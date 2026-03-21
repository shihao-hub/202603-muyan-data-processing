package main

import (
	"archive/zip"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"time"
)

const (
	baseURL     = "https://www.python.org/ftp/python"
	pythonDir   = "../python"
)

func main() {
	if len(os.Args) < 2 {
		printHelp()
		os.Exit(0)
	}

	cmd := os.Args[1]

	switch cmd {
	case "--help", "-h":
		printHelp()
	case "list":
		listVersions()
	case "download":
		if len(os.Args) < 3 {
			fmt.Println("错误: 请指定要下载的版本")
			fmt.Println("示例: python-downloader download 3.12.8")
			os.Exit(1)
		}
		downloadVersion(os.Args[2])
	default:
		fmt.Printf("未知命令: %s\n", cmd)
		printHelp()
		os.Exit(1)
	}
}

func printHelp() {
	fmt.Println(`python-downloader - Python嵌入式版本下载工具

用法:
  python-downloader list              列出可用版本
  python-downloader download <版本>   下载指定版本
  python-downloader --help           显示帮助

示例:
  python-downloader list
  python-downloader download 3.12.8

说明:
  下载的Python将保存到 ../python 目录`)
}

func listVersions() {
	fmt.Println("正在获取可用版本...")

	// 获取版本列表
	versions, err := fetchVersions()
	if err != nil {
		fmt.Printf("错误: 获取版本列表失败 - %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("\n可用版本 (%d个):\n", len(versions))
	fmt.Println("─────────────────────────────────")

	// 显示最新版本优先
	for i := len(versions) - 1; i >= 0; i-- {
		v := versions[i]
		if strings.HasPrefix(v, "3.12") {
			fmt.Printf("  * %s (推荐)\n", v)
		} else {
			fmt.Printf("    %s\n", v)
		}
	}
}

func fetchVersions() ([]string, error) {
	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Get(baseURL + "/")
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	// 解析版本目录
	re := regexp.MustCompile(`href="(\d+\.\d+\.\d+)/"`)
	matches := re.FindAllStringSubmatch(string(body), -1)

	versions := make([]string, 0, len(matches))
	seen := make(map[string]bool)

	for _, m := range matches {
		ver := m[1]
		if !seen[ver] && hasEmbeddable(ver) {
			versions = append(versions, ver)
			seen[ver] = true
		}
	}

	// 排序
	sort.Slice(versions, func(i, j int) bool {
		return compareVersions(versions[i], versions[j]) < 0
	})

	return versions, nil
}

func hasEmbeddable(version string) bool {
	// 检查该版本是否有嵌入式包
	url := fmt.Sprintf("%s/%s/python-%s-embed-amd64.zip", baseURL, version, version)
	resp, err := http.Head(url)
	if err != nil {
		return false
	}
	defer resp.Body.Close()
	return resp.StatusCode == 200
}

func compareVersions(a, b string) int {
	partsA := strings.Split(a, ".")
	partsB := strings.Split(b, ".")

	for i := 0; i < len(partsA) && i < len(partsB); i++ {
		var ia, ib int
		fmt.Sscanf(partsA[i], "%d", &ia)
		fmt.Sscanf(partsB[i], "%d", &ib)
		if ia != ib {
			return ia - ib
		}
	}
	return len(partsA) - len(partsB)
}

type Action int

const (
	DOWNLOAD Action = iota
	SKIP
	OVERWRITE
	QUIT
)

func checkPythonDir(version string) Action {
	// 检查python目录是否存在
	info, err := os.Stat(pythonDir)
	if os.IsNotExist(err) {
		return DOWNLOAD
	}
	if err != nil {
		fmt.Printf("错误: 无法检查目录 - %v\n", err)
		return QUIT
	}
	if !info.IsDir() {
		fmt.Println("错误: ../python 存在但不是目录")
		return QUIT
	}

	// 检查目录是否为空
	entries, err := os.ReadDir(pythonDir)
	if err != nil {
		fmt.Printf("错误: 无法读取目录 - %v\n", err)
		return QUIT
	}

	if len(entries) == 0 {
		return DOWNLOAD
	}

	// 检查版本
	existingVersion := detectExistingVersion()
	if existingVersion == version {
		fmt.Printf("版本 %s 已存在，跳过下载\n", version)
		return SKIP
	}

	// 不同版本，询问用户
	fmt.Printf("python目录已存在 (版本: %s)\n", existingVersion)
	fmt.Printf("将下载版本: %s\n\n", version)
	fmt.Println("请选择操作:")
	fmt.Println("  [Y] 覆盖下载 (删除旧版本，重新下载)")
	fmt.Println("  [N] 跳过下载 (使用现有版本)")
	fmt.Println("  [Q] 退出")

	fmt.Print("\n请输入选择 [Y/N/Q]: ")

	var choice string
	fmt.Scan(&choice)
	choice = strings.ToUpper(choice)

	switch choice {
	case "Y":
		return OVERWRITE
	case "N":
		fmt.Println("跳过下载，使用现有版本")
		return SKIP
	default:
		fmt.Println("退出")
		return QUIT
	}
}

func detectExistingVersion() string {
	// 尝试从python.exe获取版本
	pythonExe := filepath.Join(pythonDir, "python.exe")
	if _, err := os.Stat(pythonExe); err == nil {
		// 尝试运行python --version
		return "unknown (检测失败)"
	}
	return "unknown"
}

func downloadVersion(version string) {
	fmt.Printf("准备下载 Python %s 嵌入式版本...\n", version)

	action := checkPythonDir(version)

	switch action {
	case SKIP:
		return
	case QUIT:
		os.Exit(1)
	case OVERWRITE:
		fmt.Println("删除旧版本...")
		if err := os.RemoveAll(pythonDir); err != nil {
			fmt.Printf("错误: 删除旧目录失败 - %v\n", err)
			os.Exit(1)
		}
	}

	fmt.Println("\n开始下载...")

	// 下载
	url := fmt.Sprintf("%s/%s/python-%s-embed-amd64.zip", baseURL, version, version)
	zipPath := filepath.Join(pythonDir, "..", fmt.Sprintf("python-%s-embed-amd64.zip", version))

	// 确保目标目录存在
	os.MkdirAll(pythonDir, 0755)

	if err := downloadFile(url, zipPath); err != nil {
		fmt.Printf("错误: 下载失败 - %v\n", err)
		os.Exit(1)
	}

	fmt.Println("下载完成，开始解压...")

	// 解压
	if err := unzip(zipPath, pythonDir); err != nil {
		fmt.Printf("错误: 解压失败 - %v\n", err)
		os.Exit(1)
	}

	// 清理zip文件
	os.Remove(zipPath)

	fmt.Printf("\n✓ Python %s 安装完成！\n", version)
	fmt.Printf("  安装位置: %s\n", filepath.Join(filepath.Dir(pythonDir), pythonDir))
	fmt.Println("\n现在可以运行 launcher.bat 启动材料匹配工具")
}

func downloadFile(url, dest string) error {
	resp, err := http.Get(url)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return fmt.Errorf("HTTP %d", resp.StatusCode)
	}

	out, err := os.Create(dest)
	if err != nil {
		return err
	}
	defer out.Close()

	// 显示进度
	size := resp.ContentLength
	downloaded := int64(0)
	buf := make([]byte, 32768)

	fmt.Println()

	for {
		n, err := resp.Body.Read(buf)
		if n > 0 {
			out.Write(buf[:n])
			downloaded += int64(n)
			if size > 0 {
				percent := float64(downloaded) / float64(size) * 100
				fmt.Printf("\r  下载中: %.1f%% (%d/%d bytes)", percent, downloaded, size)
			}
		}
		if err == io.EOF {
			break
		}
		if err != nil {
			return err
		}
	}

	fmt.Println("\r  下载完成                    ")
	return nil
}

func unzip(src, dest string) error {
	reader, err := zip.OpenReader(src)
	if err != nil {
		return err
	}
	defer reader.Close()

	if err := os.MkdirAll(dest, 0755); err != nil {
		return err
	}

	for _, file := range reader.File {
		path := filepath.Join(dest, file.Name)

		if file.FileInfo().IsDir() {
			os.MkdirAll(path, file.Mode())
			continue
		}

		reader, err := file.Open()
		if err != nil {
			return err
		}

		writer, err := os.Create(path)
		if err != nil {
			reader.Close()
			return err
		}

		io.Copy(writer, reader)
		writer.Close()
		reader.Close()

		// 设置权限
		os.Chmod(path, file.Mode())
	}

	return nil
}

package main

import (
	"archive/zip"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"runtime"
	"sort"
	"strings"
	"time"
)

const (
	pythonDir = "../python"
)

var (
	mirrors = []struct {
		name string
		url  string
	}{
		{"python.org", "https://www.python.org/ftp/python"},
		{"tuna", "https://mirrors.tuna.tsinghua.edu.cn/python"},
		{"aliyun", "https://mirrors.aliyun.com/python"},
	}
	mirrorTimeout = 5 * time.Second
)

type versionCache struct {
	Updated  string   `json:"updated"`
	Versions []string `json:"versions"`
	Source   string   `json:"source"`
}

func getCachePath() string {
	var appData string
	if runtime.GOOS == "windows" {
		appData = os.Getenv("APPDATA")
		if appData == "" {
			appData = filepath.Join(os.Getenv("USERPROFILE"), "AppData", "Roaming")
		}
	} else {
		appData = os.Getenv("HOME")
		if appData == "" {
			appData = os.TempDir()
		}
	}
	dir := filepath.Join(appData, "python-downloader")
	os.MkdirAll(dir, 0755)
	return filepath.Join(dir, "versions.json")
}

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
  下载的Python将保存到 ../python 目录
  版本列表缓存位置: %APPDATA%/python-downloader/versions.json`)
}

func listVersions() {
	// 先读取缓存，立即显示
	cache := readCache()
	if cache != nil && len(cache.Versions) > 0 {
		displayVersions(cache.Versions, cache.Source, cache.Updated, true)
	}

	// 后台获取最新数据
	done := make(chan bool)
	go func() {
		defer close(done)

		versions, source, err := fetchVersionsWithFallback()
		if err != nil {
			if cache == nil {
				fmt.Printf("\n错误: 无法获取版本列表 - %v\n", err)
				fmt.Println("提示: 请检查网络连接或稍后重试")
			}
			return
		}

		// 更新缓存
		saveCache(versions, source)

		// 刷新显示
		displayVersions(versions, source, time.Now().Format(time.RFC3339), false)
	}()

	// 显示loading动画
	spins := []string{"-", "\\", "|", "/"}
	i := 0
	for {
		select {
		case <-done:
			return
		default:
			if cache != nil {
				// 有缓存，不显示loading
				time.Sleep(100 * time.Millisecond)
				// 检查是否完成
				select {
				case <-done:
					return
				default:
				}
			}
			fmt.Printf("\r  正在获取版本... %s ", spins[i%4])
			i++
			time.Sleep(200 * time.Millisecond)
		}
	}
}

func displayVersions(versions []string, source, updated string, isCached bool) {
	// 清除loading行
	fmt.Print("\r                                                              \r")

	// 显示头信息
	fmt.Println()
	if isCached && updated != "" {
		t, err := time.Parse(time.RFC3339, updated)
		if err == nil {
			localTime := t.Local().Format("2006-01-02 15:04")
			fmt.Printf("  [缓存于 %s | 来源: %s]\n", localTime, source)
		}
	} else {
		fmt.Printf("  [实时 | 来源: %s]\n", source)
	}
	fmt.Println()

	// 显示版本列表（最新在前）
	fmt.Printf("可用版本 (%d个):\n", len(versions))
	fmt.Println("─────────────────────────────────")

	for i := len(versions) - 1; i >= 0; i-- {
		fmt.Printf("    %s\n", versions[i])
	}
	fmt.Println()
}

func fetchVersionsWithFallback() ([]string, string, error) {
	for _, mirror := range mirrors {
		versions, err := fetchVersionsFromMirror(mirror.url)
		if err == nil {
			return versions, mirror.name, nil
		}
	}
	return nil, "", fmt.Errorf("所有镜像源均无法访问")
}

func fetchVersionsFromMirror(baseURL string) ([]string, error) {
	client := &http.Client{Timeout: mirrorTimeout}

	resp, err := client.Get(baseURL + "/")
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("HTTP %d", resp.StatusCode)
	}

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
		if !seen[ver] {
			versions = append(versions, ver)
			seen[ver] = true
		}
	}

	// 排序（最新在前）
	sort.Slice(versions, func(i, j int) bool {
		return compareVersions(versions[i], versions[j]) > 0
	})

	return versions, nil
}

func readCache() *versionCache {
	path := getCachePath()
	data, err := os.ReadFile(path)
	if err != nil {
		return nil
	}

	var cache versionCache
	if err := json.Unmarshal(data, &cache); err != nil {
		return nil
	}
	return &cache
}

func saveCache(versions []string, source string) {
	cache := versionCache{
		Updated:  time.Now().Format(time.RFC3339),
		Versions: versions,
		Source:   source,
	}

	data, err := json.MarshalIndent(cache, "", "  ")
	if err != nil {
		return
	}

	path := getCachePath()
	os.WriteFile(path, data, 0644)
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
	pythonExe := filepath.Join(pythonDir, "python.exe")
	if _, err := os.Stat(pythonExe); err == nil {
		return "unknown"
	}
	return "unknown"
}

func downloadVersion(version string) {
	fmt.Printf("准备下载 Python %s 嵌入式版本...\n", version)

	// 获取下载地址
	url, source, err := findDownloadURL(version)
	if err != nil {
		fmt.Printf("错误: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("使用镜像源: %s\n", source)

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

	fmt.Printf("\n[OK] Python %s 安装完成！\n", version)
	fmt.Printf("  安装位置: %s\n", filepath.Join(filepath.Dir(pythonDir), pythonDir))
	fmt.Println("\n现在可以运行 launcher.bat 启动材料匹配工具")
}

func findDownloadURL(version string) (string, string, error) {
	for _, mirror := range mirrors {
		url := fmt.Sprintf("%s/%s/python-%s-embed-amd64.zip", mirror.url, version, version)
		if exists, _ := urlExists(url); exists {
			return url, mirror.name, nil
		}
	}
	return "", "", fmt.Errorf("无法找到版本 %s 的下载链接", version)
}

func urlExists(url string) (bool, error) {
	client := &http.Client{Timeout: 3 * time.Second}
	resp, err := client.Head(url)
	if err != nil {
		return false, nil
	}
	defer resp.Body.Close()
	return resp.StatusCode == 200, nil
}

func downloadFile(url, dest string) error {
	client := &http.Client{Timeout: 120 * time.Second}
	resp, err := client.Get(url)
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

		os.Chmod(path, file.Mode())
	}

	return nil
}

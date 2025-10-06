# Docker 快速启动脚本
# 使用方法: .\docker-run.ps1 [选项]

param(
    [string]$Mode = "help",
    [string]$InputPath = "./input",
    [string]$OutputPath = "./output"
)

function Show-Help {
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host "  Sora2 Watermark Remover - Docker  " -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "使用方法:" -ForegroundColor Yellow
    Write-Host "  .\docker-run.ps1 -Mode <模式> [-InputPath <输入路径>] [-OutputPath <输出路径>]" -ForegroundColor White
    Write-Host ""
    Write-Host "可用模式:" -ForegroundColor Yellow
    Write-Host "  build       - 构建 Docker 镜像" -ForegroundColor Green
    Write-Host "  single      - 处理单张图片" -ForegroundColor Green
    Write-Host "  batch       - 批量处理文件夹" -ForegroundColor Green
    Write-Host "  help        - 显示命令行帮助" -ForegroundColor Green
    Write-Host "  shell       - 进入容器终端" -ForegroundColor Green
    Write-Host ""
    Write-Host "示例:" -ForegroundColor Yellow
    Write-Host "  # 构建镜像" -ForegroundColor White
    Write-Host "  .\docker-run.ps1 -Mode build" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  # 处理单张图片" -ForegroundColor White
    Write-Host "  .\docker-run.ps1 -Mode single -InputPath './input/photo.jpg' -OutputPath './output/photo.jpg'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  # 批量处理整个文件夹" -ForegroundColor White
    Write-Host "  .\docker-run.ps1 -Mode batch" -ForegroundColor Gray
    Write-Host ""
}

function Build-Image {
    Write-Host "构建 Docker 镜像..." -ForegroundColor Cyan
    docker-compose build
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ 镜像构建成功!" -ForegroundColor Green
    } else {
        Write-Host "✗ 镜像构建失败!" -ForegroundColor Red
        exit 1
    }
}

function Invoke-SingleProcess {
    Write-Host "处理单张图片: $InputPath -> $OutputPath" -ForegroundColor Cyan
    
    # 确保输入输出目录存在
    $inputDir = Split-Path -Parent $InputPath
    $outputDir = Split-Path -Parent $OutputPath
    
    if (-not (Test-Path $inputDir)) {
        Write-Host "✗ 输入文件不存在: $InputPath" -ForegroundColor Red
        exit 1
    }
    
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    
    docker-compose run --rm watermark-remover python remwm.py `
        --input "/app/$InputPath" `
        --output "/app/$OutputPath"
}

function Invoke-BatchProcess {
    Write-Host "批量处理文件夹: $InputPath -> $OutputPath" -ForegroundColor Cyan
    
    # 确保输入输出目录存在
    if (-not (Test-Path $InputPath)) {
        Write-Host "创建输入目录: $InputPath" -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $InputPath -Force | Out-Null
        Write-Host "请将需要处理的图片放入 $InputPath 目录" -ForegroundColor Yellow
        exit 0
    }
    
    if (-not (Test-Path $OutputPath)) {
        Write-Host "创建输出目录: $OutputPath" -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    docker-compose run --rm watermark-remover python remwm.py `
        --input /app/input `
        --output /app/output `
        --recursive
}

function Show-CommandHelp {
    Write-Host "显示 remwm.py 命令行帮助..." -ForegroundColor Cyan
    docker-compose run --rm watermark-remover python remwm.py --help
}

function Enter-Shell {
    Write-Host "进入容器终端..." -ForegroundColor Cyan
    docker-compose run --rm watermark-remover bash
}

# 主逻辑
switch ($Mode.ToLower()) {
    "build" {
        Build-Image
    }
    "single" {
        Invoke-SingleProcess
    }
    "batch" {
        Invoke-BatchProcess
    }
    "help" {
        Show-CommandHelp
    }
    "shell" {
        Enter-Shell
    }
    default {
        Show-Help
    }
}

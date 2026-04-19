#!/bin/bash

# ============================================
# Priority First 测试启动脚本 v2.0
# ============================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$PROJECT_ROOT/backend"
FRONTEND_DIR="$PROJECT_ROOT/frontend"
ADMIN_DIR="$PROJECT_ROOT/admin"

echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     Priority First 测试启动脚本 v2.0      ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
echo ""

# 检查目录是否存在
if [ ! -d "$BACKEND_DIR" ]; then
    echo -e "${RED}错误: backend 目录不存在: $BACKEND_DIR${NC}"
    exit 1
fi

if [ ! -d "$FRONTEND_DIR" ]; then
    echo -e "${RED}错误: frontend 目录不存在: $FRONTEND_DIR${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 项目目录检查通过${NC}"
echo -e "  根目录:   $PROJECT_ROOT"
echo -e "  后端:     $BACKEND_DIR"
echo -e "  前端:     $FRONTEND_DIR"
echo -e "  管理平台: $ADMIN_DIR"
echo ""

# ============================================
# 步骤1: 启动后端
# ============================================
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}[步骤 1/4] 启动后端服务${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

cd "$BACKEND_DIR"

# 检查 node_modules
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}后端依赖未安装，正在安装...${NC}"
    npm install
fi

# 检查后端端口是否被占用
BACKEND_PORT=8110
if lsof -i :$BACKEND_PORT >/dev/null 2>&1; then
    echo -e "${YELLOW}端口 $BACKEND_PORT 已被占用，服务已在运行${NC}"
else
    echo -e "${BLUE}启动后端服务 (端口: $BACKEND_PORT)...${NC}"
    npm start > /dev/null 2>&1 &
    BACKEND_PID=$!
    sleep 3
    echo -e "${GREEN}✓ 后端服务已启动 (PID: $BACKEND_PID)${NC}"
fi

echo -e "${GREEN}✓ 后端API: http://localhost:$BACKEND_PORT${NC}"

# ============================================
# 步骤2: 启动管理平台
# ============================================
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}[步骤 2/4] 启动管理平台${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

ADMIN_PORT=5178
if lsof -i :$ADMIN_PORT >/dev/null 2>&1; then
    echo -e "${YELLOW}端口 $ADMIN_PORT 已被占用，管理平台已在运行${NC}"
else
    if [ -d "$ADMIN_DIR" ]; then
        cd "$ADMIN_DIR"
        if [ ! -d "node_modules" ]; then
            echo -e "${YELLOW}管理平台依赖未安装，正在安装...${NC}"
            npm install
        fi
        echo -e "${BLUE}启动管理平台...${NC}"
        npm run dev > /dev/null 2>&1 &
        ADMIN_PID=$!
        sleep 2
        echo -e "${GREEN}✓ 管理平台已启动 (PID: $ADMIN_PID)${NC}"
    fi
fi

echo -e "${GREEN}✓ 管理平台: http://localhost:$ADMIN_PORT/admin/${NC}"

# ============================================
# 步骤3: Flutter 代码分析
# ============================================
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}[步骤 3/4] Flutter 代码分析${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

cd "$FRONTEND_DIR"

echo -e "${BLUE}运行 flutter analyze...${NC}"
ANALYZE_RESULT=$(flutter analyze 2>&1)
echo "$ANALYZE_RESULT"

# 检查是否有错误
if echo "$ANALYZE_RESULT" | grep -q "error •"; then
    echo -e "${RED}✗ 代码分析发现错误，请修复后再运行${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 代码分析通过${NC}"

# ============================================
# 步骤4: 运行 Flutter 应用
# ============================================
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}[步骤 4/4] 启动 Flutter 应用 (Android)${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 检查 Flutter 设备
echo -e "${BLUE}检查可用设备...${NC}"
FLUTTER_DEVICES=$(flutter devices 2>&1)
echo "$FLUTTER_DEVICES"
echo ""

# 查找 Android 设备 (格式: "设备名 (mobile) • 设备ID • ...")
ANDROID_DEVICE=$(echo "$FLUTTER_DEVICES" | grep -oP '• \K[a-z0-9]+(?= •)' | head -1)

if [ -z "$ANDROID_DEVICE" ]; then
    echo -e "${RED}✗ 未检测到 Android 设备！${NC}"
    echo -e "${YELLOW}请确保:${NC}"
    echo -e "${YELLOW}  1. 已连接 Android 真机并开启 USB 调试${NC}"
    echo -e "${YELLOW}  2. 或已启动 Android 模拟器${NC}"
    echo -e "${YELLOW}  3. 运行 'flutter devices' 查看可用设备${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 检测到设备: $ANDROID_DEVICE${NC}"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}服务已启动，按 Ctrl+C 退出${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}后端API:     http://localhost:8110${NC}"
echo -e "${GREEN}管理平台:    http://localhost:5178/admin/${NC}"
echo ""
echo -e "${YELLOW}提示: 按 'q' 退出 Flutter 应用${NC}"
echo ""

flutter run -d $ANDROID_DEVICE

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Flutter 应用已退出${NC}"
echo -e "${GREEN}后端服务和管理平台仍在运行${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

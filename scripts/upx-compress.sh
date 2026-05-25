#!/bin/bash
# ============================================================
# upx-compress.sh — 方案 C：在 feeds install 后、make 前
# 修改目标包的 Makefile，在 Package/install 阶段注入 UPX 压缩
# ============================================================
set -e

OPENWRT_ROOT="${1:-.}"
UPX_ARGS="--best --lzma"

echo "=========================================="
echo "  UPX Compress — Makefile Patch Script"
echo "=========================================="
echo "OpenWrt root: $OPENWRT_ROOT"
echo ""

PATCHED=0

# ----------------------------------------------------------
# 通用函数：在 Makefile 中找到目标二进制的 INSTALL_BIN/CP 行，
# 在其后插入 UPX 压缩指令
# ----------------------------------------------------------
inject_upx_after_install() {
    local makefile="$1"
    local bin_keyword="$2"   # 匹配行的关键词，如 "openlist" 或 "clash_meta"
    local upx_target="$3"    # UPX 压缩目标路径，如 "$(1)/usr/bin/openlist"
    local label="$4"

    if [ ! -f "$makefile" ]; then
        echo "  ⚠ 文件不存在: $makefile"
        return 0
    fi

    # 检查是否已 patch 过
    if grep -q "upx-compress" "$makefile" 2>/dev/null; then
        echo "  ✓ 已 patch，跳过: $label"
        return 0
    fi

    # 找到包含目标关键词的 INSTALL_BIN 或 CP 行，在其后插入 UPX
    # 使用 | 作为 sed 分隔符避免路径冲突
    if grep -q "$bin_keyword" "$makefile"; then
        sed -i "\|$bin_keyword|a\\
\tupx $UPX_TARGET $upx_target 2>/dev/null || true # upx-compress" "$makefile"
        # 修正变量名
        sed -i "s|UPX_TARGET|$UPX_ARGS|g" "$makefile"
        echo "  ✓ 已 patch: $label"
        PATCHED=$((PATCHED + 1))
    else
        echo "  ⚠ 未匹配关键词 '$bin_keyword' in $(basename "$makefile")"
    fi
}

# ----------------------------------------------------------
# 通用函数：在 Makefile 的 define Package/xxx/install 块末尾
# （endef 之前）插入一行命令
# ----------------------------------------------------------
inject_upx_before_endef() {
    local makefile="$1"
    local upx_cmd="$2"
    local label="$3"

    if [ ! -f "$makefile" ]; then
        echo "  ⚠ 文件不存在: $makefile"
        return 0
    fi

    if grep -q "upx-compress" "$makefile" 2>/dev/null; then
        echo "  ✓ 已 patch，跳过: $label"
        return 0
    fi

    # 在所有 endef 行前插入 UPX 命令
    # 这样每个 install 段都会执行压缩
    sed -i "/^[[:space:]]*endef/i\\
\t$upx_cmd # upx-compress" "$makefile"

    echo "  ✓ 已 patch: $label (before endef)"
    PATCHED=$((PATCHED + 1))
}

# ----------------------------------------------------------
# 1. luci-app-openlist（或 openlist2、alist）
# ----------------------------------------------------------
echo "[1/2] 查找 OpenList..."

OPENLIST_MAKEFILE=""
for candidate in \
    "$OPENWRT_ROOT/package/feeds/openlist/openlist/Makefile" \
    "$OPENWRT_ROOT/feeds/openlist/openlist/Makefile" \
    "$OPENWRT_ROOT/package/feeds/packages/openlist/Makefile" \
    "$OPENWRT_ROOT/package/feeds/packages/alist/Makefile" \
    "$OPENWRT_ROOT/package/feeds/luci/luci-app-openlist/Makefile" \
    "$OPENWRT_ROOT/package/feeds/luci/luci-app-openlist2/Makefile" \
    "$OPENWRT_ROOT/feeds/openlist/luci-app-openlist2/Makefile" \
    "$OPENWRT_ROOT/feeds/packages/net/openlist/Makefile" \
    "$OPENWRT_ROOT/feeds/packages/net/alist/Makefile" \
    "$OPENWRT_ROOT/feeds/luci/applications/luci-app-openlist/Makefile" \
    "$OPENWRT_ROOT/feeds/luci/applications/luci-app-openlist2/Makefile"
do
    if [ -f "$candidate" ]; then
        OPENLIST_MAKEFILE="$candidate"
        break
    fi
done

if [ -z "$OPENLIST_MAKEFILE" ]; then
    echo "  搜索中..."
    OPENLIST_MAKEFILE=$(find "$OPENWRT_ROOT/feeds" "$OPENWRT_ROOT/package" \
        -name "Makefile" \( -path "*openlist*" -o -path "*alist*" \) \
        2>/dev/null | grep -v ".git" | head -1)
fi

if [ -n "$OPENLIST_MAKEFILE" ]; then
    echo "  找到: $OPENLIST_MAKEFILE"
    # 检查二进制名
    if grep -q "openlist" "$OPENLIST_MAKEFILE"; then
        inject_upx_after_install "$OPENLIST_MAKEFILE" "openlist" '$(1)/usr/bin/openlist' "OpenList(openlist)"
    fi
    if grep -q "/alist" "$OPENLIST_MAKEFILE"; then
        inject_upx_after_install "$OPENLIST_MAKEFILE" "/alist" '$(1)/usr/bin/alist' "OpenList(alist)"
    fi
    # 如果上面都没匹配，尝试通用方式
    if ! grep -q "upx-compress" "$OPENLIST_MAKEFILE" 2>/dev/null; then
        echo "  尝试通用 before-endef 注入..."
        inject_upx_before_endef "$OPENLIST_MAKEFILE" \
            '[ -f $(1)/usr/bin/openlist ] && upx --best --lzma $(1)/usr/bin/openlist 2>/dev/null || true' \
            "OpenList(generic)"
    fi
else
    echo "  ⚠ 未找到 OpenList Makefile"
fi

# ----------------------------------------------------------
# 2. luci-app-openclash
# ----------------------------------------------------------
echo ""
echo "[2/2] 查找 OpenClash..."

OPENCLASH_MAKEFILE=""
for candidate in \
    "$OPENWRT_ROOT/package/feeds/luci/luci-app-openclash/Makefile" \
    "$OPENWRT_ROOT/feeds/luci/applications/luci-app-openclash/Makefile" \
    "$OPENWRT_ROOT/package/feeds/packages/openclash/Makefile" \
    "$OPENWRT_ROOT/feeds/packages/net/openclash/Makefile"
do
    if [ -f "$candidate" ]; then
        OPENCLASH_MAKEFILE="$candidate"
        break
    fi
done

if [ -z "$OPENCLASH_MAKEFILE" ]; then
    echo "  搜索中..."
    OPENCLASH_MAKEFILE=$(find "$OPENWRT_ROOT/feeds" "$OPENWRT_ROOT/package" \
        -name "Makefile" -path "*openclash*" \
        2>/dev/null | grep -v ".git" | head -1)
fi

if [ -n "$OPENCLASH_MAKEFILE" ]; then
    echo "  找到: $OPENCLASH_MAKEFILE"
    
    # OpenClash 核心二进制名称可能是 clash, clash_meta, mihomo
    for core_name in clash clash_meta mihomo; do
        if grep -q "$core_name" "$OPENCLASH_MAKEFILE"; then
            inject_upx_after_install "$OPENCLASH_MAKEFILE" \
                "$core_name" \
                "\$(1)/usr/share/openclash/core/$core_name" \
                "OpenClash($core_name)"
        fi
    done
    
    # 如果上面都没匹配，用通用方式
    if ! grep -q "upx-compress" "$OPENCLASH_MAKEFILE" 2>/dev/null; then
        echo "  尝试通用 before-endef 注入..."
        inject_upx_before_endef "$OPENCLASH_MAKEFILE" \
            'for core in $(1)/usr/share/openclash/core/*; do [ -f "$$core" ] && upx --best --lzma "$$core" 2>/dev/null || true; done' \
            "OpenClash(generic)"
    fi
else
    echo "  ⚠ 未找到 OpenClash Makefile"
fi

# ----------------------------------------------------------
# 总结
# ----------------------------------------------------------
echo ""
echo "=========================================="
if [ "$PATCHED" -gt 0 ]; then
    echo "  ✓ 共 patch $PATCHED 个 Makefile"
else
    echo "  ⚠ 未 patch 任何 Makefile（可能包未被 feeds 引入）"
fi
echo "=========================================="

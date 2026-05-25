include $(TOPDIR)/rules.mk

PKG_NAME:=openlist
PKG_VERSION:=beta
PKG_RELEASE:=1

# Download pre-built binary from GitHub releases
PKG_SOURCE:=$(PKG_NAME)-linux-aarch64.tar.gz
PKG_SOURCE_URL:=https://github.com/OpenListTeam/OpenList/releases/download/$(PKG_VERSION)/
PKG_HASH:=skip

include $(INCLUDE_DIR)/package.mk

define Package/openlist
  SECTION:=utils
  CATEGORY:=Utilities
  SUBMENU:=File Transfer
  TITLE:=OpenList - A file list program
  URL:=https://github.com/OpenListTeam/OpenList
  DEPENDS:=@(aarch64)
endef

define Package/openlist/description
  OpenList is a file list program that supports multiple storage,
  powered by Gin and React.
endef

define Build/Compile
	# Pre-built binary, nothing to compile
endef

define Package/openlist/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/openlist $(1)/usr/bin/openlist
	# UPX compress to reduce firmware size (144MB -> ~10MB)
	upx --best --lzma $(1)/usr/bin/openlist 2>/dev/null || echo "UPX compression skipped/failed"
endef

$(eval $(call BuildPackage,openlist))

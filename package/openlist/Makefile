include $(TOPDIR)/rules.mk

PKG_NAME:=openlist
PKG_VERSION:=beta
PKG_RELEASE:=1

# Download pre-built binary from GitHub releases
PKG_SOURCE:=$(PKG_NAME)-linux-arm64.tar.gz
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
	# Pre-built binary, strip debug symbols
	$(STRIP) $(PKG_BUILD_DIR)/openlist
endef

define Package/openlist/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(CP) $(PKG_BUILD_DIR)/openlist $(1)/usr/bin/openlist
endef

$(eval $(call BuildPackage,openlist))

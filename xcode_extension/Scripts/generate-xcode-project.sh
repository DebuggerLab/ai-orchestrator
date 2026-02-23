#!/bin/bash
#
# Generate Xcode Project for AI Orchestrator Extension
# Copyright © 2026 DebuggerLab. All rights reserved.
#
# This script creates a proper Xcode project that can build a Source Editor Extension.
# XcodeKit is automatically linked when using the proper target type.
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
XCODEPROJ="$PROJECT_DIR/AIOrchestratorXcode.xcodeproj"

echo "Generating Xcode project structure..."

# Remove old project if exists
rm -rf "$XCODEPROJ"

# Create project directory
mkdir -p "$XCODEPROJ"

# Generate a unique project UUID
generate_uuid() {
    python3 -c "import uuid; print(uuid.uuid4().hex[:24].upper())"
}

# Generate UUIDs for various components
PROJECT_UUID=$(generate_uuid)
MAIN_GROUP_UUID=$(generate_uuid)
SOURCES_GROUP_UUID=$(generate_uuid)
PRODUCTS_GROUP_UUID=$(generate_uuid)
RESOURCES_GROUP_UUID=$(generate_uuid)
FRAMEWORKS_GROUP_UUID=$(generate_uuid)

# Container app UUIDs
CONTAINER_TARGET_UUID=$(generate_uuid)
CONTAINER_BUILDCONFIG_DEBUG_UUID=$(generate_uuid)
CONTAINER_BUILDCONFIG_RELEASE_UUID=$(generate_uuid)
CONTAINER_CONFIGLIST_UUID=$(generate_uuid)
CONTAINER_SOURCES_PHASE_UUID=$(generate_uuid)
CONTAINER_FRAMEWORKS_PHASE_UUID=$(generate_uuid)
CONTAINER_RESOURCES_PHASE_UUID=$(generate_uuid)
CONTAINER_EMBED_PHASE_UUID=$(generate_uuid)
CONTAINER_PRODUCT_UUID=$(generate_uuid)

# Extension UUIDs
EXT_TARGET_UUID=$(generate_uuid)
EXT_BUILDCONFIG_DEBUG_UUID=$(generate_uuid)
EXT_BUILDCONFIG_RELEASE_UUID=$(generate_uuid)
EXT_CONFIGLIST_UUID=$(generate_uuid)
EXT_SOURCES_PHASE_UUID=$(generate_uuid)
EXT_FRAMEWORKS_PHASE_UUID=$(generate_uuid)
EXT_RESOURCES_PHASE_UUID=$(generate_uuid)
EXT_PRODUCT_UUID=$(generate_uuid)

# Project configuration UUIDs
PROJECT_BUILDCONFIG_DEBUG_UUID=$(generate_uuid)
PROJECT_BUILDCONFIG_RELEASE_UUID=$(generate_uuid)
PROJECT_CONFIGLIST_UUID=$(generate_uuid)

# File reference UUIDs
XCODEKIT_UUID=$(generate_uuid)
APPKIT_UUID=$(generate_uuid)
INFOPLIST_CONTAINER_UUID=$(generate_uuid)
INFOPLIST_EXT_UUID=$(generate_uuid)
ENTITLEMENTS_UUID=$(generate_uuid)

# Source file UUIDs (we'll generate these dynamically)
declare -A SOURCE_UUIDS
declare -A BUILDFILE_UUIDS

# Function to add source file
add_source_file() {
    local file_path="$1"
    local relative_path="${file_path#$PROJECT_DIR/Sources/}"
    SOURCE_UUIDS["$relative_path"]=$(generate_uuid)
    BUILDFILE_UUIDS["$relative_path"]=$(generate_uuid)
}

# Find all Swift source files
while IFS= read -r -d '' file; do
    add_source_file "$file"
done < <(find "$PROJECT_DIR/Sources" -name "*.swift" -print0)

# Create pbxproj file
cat > "$XCODEPROJ/project.pbxproj" << 'PBXPROJ_HEADER'
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {

PBXPROJ_HEADER

# Add PBXBuildFile section
echo "/* Begin PBXBuildFile section */" >> "$XCODEPROJ/project.pbxproj"

# Add build files for each source
for file in "${!BUILDFILE_UUIDS[@]}"; do
    filename=$(basename "$file")
    echo "		${BUILDFILE_UUIDS[$file]} /* $filename in Sources */ = {isa = PBXBuildFile; fileRef = ${SOURCE_UUIDS[$file]} /* $filename */; };" >> "$XCODEPROJ/project.pbxproj"
done

# Add framework build files
echo "		${XCODEKIT_UUID}1 /* XcodeKit.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = $XCODEKIT_UUID /* XcodeKit.framework */; };" >> "$XCODEPROJ/project.pbxproj"
echo "		${APPKIT_UUID}1 /* AppKit.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = $APPKIT_UUID /* AppKit.framework */; };" >> "$XCODEPROJ/project.pbxproj"

echo "/* End PBXBuildFile section */" >> "$XCODEPROJ/project.pbxproj"
echo "" >> "$XCODEPROJ/project.pbxproj"

# Add PBXContainerItemProxy section (for extension embedding)
echo "/* Begin PBXContainerItemProxy section */" >> "$XCODEPROJ/project.pbxproj"
PROXY_UUID=$(generate_uuid)
echo "		$PROXY_UUID /* PBXContainerItemProxy */ = {" >> "$XCODEPROJ/project.pbxproj"
echo "			isa = PBXContainerItemProxy;" >> "$XCODEPROJ/project.pbxproj"
echo "			containerPortal = $PROJECT_UUID /* Project object */;" >> "$XCODEPROJ/project.pbxproj"
echo "			proxyType = 1;" >> "$XCODEPROJ/project.pbxproj"
echo "			remoteGlobalIDString = $EXT_TARGET_UUID;" >> "$XCODEPROJ/project.pbxproj"
echo "			remoteInfo = \"AI Orchestrator Extension\";" >> "$XCODEPROJ/project.pbxproj"
echo "		};" >> "$XCODEPROJ/project.pbxproj"
echo "/* End PBXContainerItemProxy section */" >> "$XCODEPROJ/project.pbxproj"
echo "" >> "$XCODEPROJ/project.pbxproj"

# Add PBXCopyFilesBuildPhase section (for embedding extension)
echo "/* Begin PBXCopyFilesBuildPhase section */" >> "$XCODEPROJ/project.pbxproj"
echo "		$CONTAINER_EMBED_PHASE_UUID /* Embed App Extensions */ = {" >> "$XCODEPROJ/project.pbxproj"
echo "			isa = PBXCopyFilesBuildPhase;" >> "$XCODEPROJ/project.pbxproj"
echo "			buildActionMask = 2147483647;" >> "$XCODEPROJ/project.pbxproj"
echo "			dstPath = \"\";" >> "$XCODEPROJ/project.pbxproj"
echo "			dstSubfolderSpec = 13;" >> "$XCODEPROJ/project.pbxproj"
echo "			files = (" >> "$XCODEPROJ/project.pbxproj"
EMBED_FILE_UUID=$(generate_uuid)
echo "				$EMBED_FILE_UUID /* AI Orchestrator Extension.appex in Embed App Extensions */," >> "$XCODEPROJ/project.pbxproj"
echo "			);" >> "$XCODEPROJ/project.pbxproj"
echo "			name = \"Embed App Extensions\";" >> "$XCODEPROJ/project.pbxproj"
echo "			runOnlyForDeploymentPostprocessing = 0;" >> "$XCODEPROJ/project.pbxproj"
echo "		};" >> "$XCODEPROJ/project.pbxproj"
echo "/* End PBXCopyFilesBuildPhase section */" >> "$XCODEPROJ/project.pbxproj"
echo "" >> "$XCODEPROJ/project.pbxproj"

# Add PBXFileReference section
echo "/* Begin PBXFileReference section */" >> "$XCODEPROJ/project.pbxproj"

# Add source file references
for file in "${!SOURCE_UUIDS[@]}"; do
    filename=$(basename "$file")
    echo "		${SOURCE_UUIDS[$file]} /* $filename */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"$filename\"; sourceTree = \"<group>\"; };" >> "$XCODEPROJ/project.pbxproj"
done

# Add framework references
echo "		$XCODEKIT_UUID /* XcodeKit.framework */ = {isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = XcodeKit.framework; path = System/Library/Frameworks/XcodeKit.framework; sourceTree = SDKROOT; };" >> "$XCODEPROJ/project.pbxproj"
echo "		$APPKIT_UUID /* AppKit.framework */ = {isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = AppKit.framework; path = System/Library/Frameworks/AppKit.framework; sourceTree = SDKROOT; };" >> "$XCODEPROJ/project.pbxproj"

# Add product references
echo "		$CONTAINER_PRODUCT_UUID /* AI Orchestrator.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = \"AI Orchestrator.app\"; sourceTree = BUILT_PRODUCTS_DIR; };" >> "$XCODEPROJ/project.pbxproj"
echo "		$EXT_PRODUCT_UUID /* AI Orchestrator Extension.appex */ = {isa = PBXFileReference; explicitFileType = \"wrapper.app-extension\"; includeInIndex = 0; path = \"AI Orchestrator Extension.appex\"; sourceTree = BUILT_PRODUCTS_DIR; };" >> "$XCODEPROJ/project.pbxproj"

echo "/* End PBXFileReference section */" >> "$XCODEPROJ/project.pbxproj"
echo "" >> "$XCODEPROJ/project.pbxproj"

# Add PBXFrameworksBuildPhase section
echo "/* Begin PBXFrameworksBuildPhase section */" >> "$XCODEPROJ/project.pbxproj"
echo "		$CONTAINER_FRAMEWORKS_PHASE_UUID /* Frameworks */ = {" >> "$XCODEPROJ/project.pbxproj"
echo "			isa = PBXFrameworksBuildPhase;" >> "$XCODEPROJ/project.pbxproj"
echo "			buildActionMask = 2147483647;" >> "$XCODEPROJ/project.pbxproj"
echo "			files = (" >> "$XCODEPROJ/project.pbxproj"
echo "				${APPKIT_UUID}1 /* AppKit.framework in Frameworks */," >> "$XCODEPROJ/project.pbxproj"
echo "			);" >> "$XCODEPROJ/project.pbxproj"
echo "			runOnlyForDeploymentPostprocessing = 0;" >> "$XCODEPROJ/project.pbxproj"
echo "		};" >> "$XCODEPROJ/project.pbxproj"
echo "		$EXT_FRAMEWORKS_PHASE_UUID /* Frameworks */ = {" >> "$XCODEPROJ/project.pbxproj"
echo "			isa = PBXFrameworksBuildPhase;" >> "$XCODEPROJ/project.pbxproj"
echo "			buildActionMask = 2147483647;" >> "$XCODEPROJ/project.pbxproj"
echo "			files = (" >> "$XCODEPROJ/project.pbxproj"
echo "				${XCODEKIT_UUID}1 /* XcodeKit.framework in Frameworks */," >> "$XCODEPROJ/project.pbxproj"
echo "			);" >> "$XCODEPROJ/project.pbxproj"
echo "			runOnlyForDeploymentPostprocessing = 0;" >> "$XCODEPROJ/project.pbxproj"
echo "		};" >> "$XCODEPROJ/project.pbxproj"
echo "/* End PBXFrameworksBuildPhase section */" >> "$XCODEPROJ/project.pbxproj"
echo "" >> "$XCODEPROJ/project.pbxproj"

# Add PBXGroup section (simplified - just main groups)
echo "/* Begin PBXGroup section */" >> "$XCODEPROJ/project.pbxproj"

# Main group
echo "		$MAIN_GROUP_UUID = {" >> "$XCODEPROJ/project.pbxproj"
echo "			isa = PBXGroup;" >> "$XCODEPROJ/project.pbxproj"
echo "			children = (" >> "$XCODEPROJ/project.pbxproj"
echo "				$SOURCES_GROUP_UUID /* Sources */," >> "$XCODEPROJ/project.pbxproj"
echo "				$RESOURCES_GROUP_UUID /* Resources */," >> "$XCODEPROJ/project.pbxproj"
echo "				$FRAMEWORKS_GROUP_UUID /* Frameworks */," >> "$XCODEPROJ/project.pbxproj"
echo "				$PRODUCTS_GROUP_UUID /* Products */," >> "$XCODEPROJ/project.pbxproj"
echo "			);" >> "$XCODEPROJ/project.pbxproj"
echo "			sourceTree = \"<group>\";" >> "$XCODEPROJ/project.pbxproj"
echo "		};" >> "$XCODEPROJ/project.pbxproj"

# Products group
echo "		$PRODUCTS_GROUP_UUID /* Products */ = {" >> "$XCODEPROJ/project.pbxproj"
echo "			isa = PBXGroup;" >> "$XCODEPROJ/project.pbxproj"
echo "			children = (" >> "$XCODEPROJ/project.pbxproj"
echo "				$CONTAINER_PRODUCT_UUID /* AI Orchestrator.app */," >> "$XCODEPROJ/project.pbxproj"
echo "				$EXT_PRODUCT_UUID /* AI Orchestrator Extension.appex */," >> "$XCODEPROJ/project.pbxproj"
echo "			);" >> "$XCODEPROJ/project.pbxproj"
echo "			name = Products;" >> "$XCODEPROJ/project.pbxproj"
echo "			sourceTree = \"<group>\";" >> "$XCODEPROJ/project.pbxproj"
echo "		};" >> "$XCODEPROJ/project.pbxproj"

# Sources group
echo "		$SOURCES_GROUP_UUID /* Sources */ = {" >> "$XCODEPROJ/project.pbxproj"
echo "			isa = PBXGroup;" >> "$XCODEPROJ/project.pbxproj"
echo "			children = (" >> "$XCODEPROJ/project.pbxproj"
for file in "${!SOURCE_UUIDS[@]}"; do
    filename=$(basename "$file")
    echo "				${SOURCE_UUIDS[$file]} /* $filename */," >> "$XCODEPROJ/project.pbxproj"
done
echo "			);" >> "$XCODEPROJ/project.pbxproj"
echo "			path = Sources;" >> "$XCODEPROJ/project.pbxproj"
echo "			sourceTree = \"<group>\";" >> "$XCODEPROJ/project.pbxproj"
echo "		};" >> "$XCODEPROJ/project.pbxproj"

# Resources group
echo "		$RESOURCES_GROUP_UUID /* Resources */ = {" >> "$XCODEPROJ/project.pbxproj"
echo "			isa = PBXGroup;" >> "$XCODEPROJ/project.pbxproj"
echo "			children = (" >> "$XCODEPROJ/project.pbxproj"
echo "			);" >> "$XCODEPROJ/project.pbxproj"
echo "			path = Resources;" >> "$XCODEPROJ/project.pbxproj"
echo "			sourceTree = \"<group>\";" >> "$XCODEPROJ/project.pbxproj"
echo "		};" >> "$XCODEPROJ/project.pbxproj"

# Frameworks group
echo "		$FRAMEWORKS_GROUP_UUID /* Frameworks */ = {" >> "$XCODEPROJ/project.pbxproj"
echo "			isa = PBXGroup;" >> "$XCODEPROJ/project.pbxproj"
echo "			children = (" >> "$XCODEPROJ/project.pbxproj"
echo "				$XCODEKIT_UUID /* XcodeKit.framework */," >> "$XCODEPROJ/project.pbxproj"
echo "				$APPKIT_UUID /* AppKit.framework */," >> "$XCODEPROJ/project.pbxproj"
echo "			);" >> "$XCODEPROJ/project.pbxproj"
echo "			name = Frameworks;" >> "$XCODEPROJ/project.pbxproj"
echo "			sourceTree = \"<group>\";" >> "$XCODEPROJ/project.pbxproj"
echo "		};" >> "$XCODEPROJ/project.pbxproj"

echo "/* End PBXGroup section */" >> "$XCODEPROJ/project.pbxproj"
echo "" >> "$XCODEPROJ/project.pbxproj"

# Continue with native targets, build configurations, etc.
# Add PBXNativeTarget section
echo "/* Begin PBXNativeTarget section */" >> "$XCODEPROJ/project.pbxproj"

# Container app target
echo "		$CONTAINER_TARGET_UUID /* AI Orchestrator */ = {" >> "$XCODEPROJ/project.pbxproj"
echo "			isa = PBXNativeTarget;" >> "$XCODEPROJ/project.pbxproj"
echo "			buildConfigurationList = $CONTAINER_CONFIGLIST_UUID /* Build configuration list for PBXNativeTarget \"AI Orchestrator\" */;" >> "$XCODEPROJ/project.pbxproj"
echo "			buildPhases = (" >> "$XCODEPROJ/project.pbxproj"
echo "				$CONTAINER_SOURCES_PHASE_UUID /* Sources */," >> "$XCODEPROJ/project.pbxproj"
echo "				$CONTAINER_FRAMEWORKS_PHASE_UUID /* Frameworks */," >> "$XCODEPROJ/project.pbxproj"
echo "				$CONTAINER_RESOURCES_PHASE_UUID /* Resources */," >> "$XCODEPROJ/project.pbxproj"
echo "				$CONTAINER_EMBED_PHASE_UUID /* Embed App Extensions */," >> "$XCODEPROJ/project.pbxproj"
echo "			);" >> "$XCODEPROJ/project.pbxproj"
echo "			buildRules = (" >> "$XCODEPROJ/project.pbxproj"
echo "			);" >> "$XCODEPROJ/project.pbxproj"
echo "			dependencies = (" >> "$XCODEPROJ/project.pbxproj"
DEP_UUID=$(generate_uuid)
echo "				$DEP_UUID /* PBXTargetDependency */," >> "$XCODEPROJ/project.pbxproj"
echo "			);" >> "$XCODEPROJ/project.pbxproj"
echo "			name = \"AI Orchestrator\";" >> "$XCODEPROJ/project.pbxproj"
echo "			productName = \"AI Orchestrator\";" >> "$XCODEPROJ/project.pbxproj"
echo "			productReference = $CONTAINER_PRODUCT_UUID /* AI Orchestrator.app */;" >> "$XCODEPROJ/project.pbxproj"
echo "			productType = \"com.apple.product-type.application\";" >> "$XCODEPROJ/project.pbxproj"
echo "		};" >> "$XCODEPROJ/project.pbxproj"

# Extension target
echo "		$EXT_TARGET_UUID /* AI Orchestrator Extension */ = {" >> "$XCODEPROJ/project.pbxproj"
echo "			isa = PBXNativeTarget;" >> "$XCODEPROJ/project.pbxproj"
echo "			buildConfigurationList = $EXT_CONFIGLIST_UUID /* Build configuration list for PBXNativeTarget \"AI Orchestrator Extension\" */;" >> "$XCODEPROJ/project.pbxproj"
echo "			buildPhases = (" >> "$XCODEPROJ/project.pbxproj"
echo "				$EXT_SOURCES_PHASE_UUID /* Sources */," >> "$XCODEPROJ/project.pbxproj"
echo "				$EXT_FRAMEWORKS_PHASE_UUID /* Frameworks */," >> "$XCODEPROJ/project.pbxproj"
echo "				$EXT_RESOURCES_PHASE_UUID /* Resources */," >> "$XCODEPROJ/project.pbxproj"
echo "			);" >> "$XCODEPROJ/project.pbxproj"
echo "			buildRules = (" >> "$XCODEPROJ/project.pbxproj"
echo "			);" >> "$XCODEPROJ/project.pbxproj"
echo "			dependencies = (" >> "$XCODEPROJ/project.pbxproj"
echo "			);" >> "$XCODEPROJ/project.pbxproj"
echo "			name = \"AI Orchestrator Extension\";" >> "$XCODEPROJ/project.pbxproj"
echo "			productName = \"AI Orchestrator Extension\";" >> "$XCODEPROJ/project.pbxproj"
echo "			productReference = $EXT_PRODUCT_UUID /* AI Orchestrator Extension.appex */;" >> "$XCODEPROJ/project.pbxproj"
echo "			productType = \"com.apple.product-type.xcode-extension.source-editor\";" >> "$XCODEPROJ/project.pbxproj"
echo "		};" >> "$XCODEPROJ/project.pbxproj"

echo "/* End PBXNativeTarget section */" >> "$XCODEPROJ/project.pbxproj"
echo "" >> "$XCODEPROJ/project.pbxproj"

# Add PBXProject section
echo "/* Begin PBXProject section */" >> "$XCODEPROJ/project.pbxproj"
echo "		$PROJECT_UUID /* Project object */ = {" >> "$XCODEPROJ/project.pbxproj"
echo "			isa = PBXProject;" >> "$XCODEPROJ/project.pbxproj"
echo "			attributes = {" >> "$XCODEPROJ/project.pbxproj"
echo "				BuildIndependentTargetsInParallel = 1;" >> "$XCODEPROJ/project.pbxproj"
echo "				LastSwiftUpdateCheck = 1500;" >> "$XCODEPROJ/project.pbxproj"
echo "				LastUpgradeCheck = 1500;" >> "$XCODEPROJ/project.pbxproj"
echo "				TargetAttributes = {" >> "$XCODEPROJ/project.pbxproj"
echo "					$CONTAINER_TARGET_UUID = {" >> "$XCODEPROJ/project.pbxproj"
echo "						CreatedOnToolsVersion = 15.0;" >> "$XCODEPROJ/project.pbxproj"
echo "					};" >> "$XCODEPROJ/project.pbxproj"
echo "					$EXT_TARGET_UUID = {" >> "$XCODEPROJ/project.pbxproj"
echo "						CreatedOnToolsVersion = 15.0;" >> "$XCODEPROJ/project.pbxproj"
echo "					};" >> "$XCODEPROJ/project.pbxproj"
echo "				};" >> "$XCODEPROJ/project.pbxproj"
echo "			};" >> "$XCODEPROJ/project.pbxproj"
echo "			buildConfigurationList = $PROJECT_CONFIGLIST_UUID /* Build configuration list for PBXProject \"AIOrchestratorXcode\" */;" >> "$XCODEPROJ/project.pbxproj"
echo "			compatibilityVersion = \"Xcode 14.0\";" >> "$XCODEPROJ/project.pbxproj"
echo "			developmentRegion = en;" >> "$XCODEPROJ/project.pbxproj"
echo "			hasScannedForEncodings = 0;" >> "$XCODEPROJ/project.pbxproj"
echo "			knownRegions = (" >> "$XCODEPROJ/project.pbxproj"
echo "				en," >> "$XCODEPROJ/project.pbxproj"
echo "				Base," >> "$XCODEPROJ/project.pbxproj"
echo "			);" >> "$XCODEPROJ/project.pbxproj"
echo "			mainGroup = $MAIN_GROUP_UUID;" >> "$XCODEPROJ/project.pbxproj"
echo "			productRefGroup = $PRODUCTS_GROUP_UUID /* Products */;" >> "$XCODEPROJ/project.pbxproj"
echo "			projectDirPath = \"\";" >> "$XCODEPROJ/project.pbxproj"
echo "			projectRoot = \"\";" >> "$XCODEPROJ/project.pbxproj"
echo "			targets = (" >> "$XCODEPROJ/project.pbxproj"
echo "				$CONTAINER_TARGET_UUID /* AI Orchestrator */," >> "$XCODEPROJ/project.pbxproj"
echo "				$EXT_TARGET_UUID /* AI Orchestrator Extension */," >> "$XCODEPROJ/project.pbxproj"
echo "			);" >> "$XCODEPROJ/project.pbxproj"
echo "		};" >> "$XCODEPROJ/project.pbxproj"
echo "/* End PBXProject section */" >> "$XCODEPROJ/project.pbxproj"
echo "" >> "$XCODEPROJ/project.pbxproj"

# Add PBXResourcesBuildPhase section
echo "/* Begin PBXResourcesBuildPhase section */" >> "$XCODEPROJ/project.pbxproj"
echo "		$CONTAINER_RESOURCES_PHASE_UUID /* Resources */ = {" >> "$XCODEPROJ/project.pbxproj"
echo "			isa = PBXResourcesBuildPhase;" >> "$XCODEPROJ/project.pbxproj"
echo "			buildActionMask = 2147483647;" >> "$XCODEPROJ/project.pbxproj"
echo "			files = (" >> "$XCODEPROJ/project.pbxproj"
echo "			);" >> "$XCODEPROJ/project.pbxproj"
echo "			runOnlyForDeploymentPostprocessing = 0;" >> "$XCODEPROJ/project.pbxproj"
echo "		};" >> "$XCODEPROJ/project.pbxproj"
echo "		$EXT_RESOURCES_PHASE_UUID /* Resources */ = {" >> "$XCODEPROJ/project.pbxproj"
echo "			isa = PBXResourcesBuildPhase;" >> "$XCODEPROJ/project.pbxproj"
echo "			buildActionMask = 2147483647;" >> "$XCODEPROJ/project.pbxproj"
echo "			files = (" >> "$XCODEPROJ/project.pbxproj"
echo "			);" >> "$XCODEPROJ/project.pbxproj"
echo "			runOnlyForDeploymentPostprocessing = 0;" >> "$XCODEPROJ/project.pbxproj"
echo "		};" >> "$XCODEPROJ/project.pbxproj"
echo "/* End PBXResourcesBuildPhase section */" >> "$XCODEPROJ/project.pbxproj"
echo "" >> "$XCODEPROJ/project.pbxproj"

# Add PBXSourcesBuildPhase section
echo "/* Begin PBXSourcesBuildPhase section */" >> "$XCODEPROJ/project.pbxproj"
echo "		$CONTAINER_SOURCES_PHASE_UUID /* Sources */ = {" >> "$XCODEPROJ/project.pbxproj"
echo "			isa = PBXSourcesBuildPhase;" >> "$XCODEPROJ/project.pbxproj"
echo "			buildActionMask = 2147483647;" >> "$XCODEPROJ/project.pbxproj"
echo "			files = (" >> "$XCODEPROJ/project.pbxproj"
echo "			);" >> "$XCODEPROJ/project.pbxproj"
echo "			runOnlyForDeploymentPostprocessing = 0;" >> "$XCODEPROJ/project.pbxproj"
echo "		};" >> "$XCODEPROJ/project.pbxproj"
echo "		$EXT_SOURCES_PHASE_UUID /* Sources */ = {" >> "$XCODEPROJ/project.pbxproj"
echo "			isa = PBXSourcesBuildPhase;" >> "$XCODEPROJ/project.pbxproj"
echo "			buildActionMask = 2147483647;" >> "$XCODEPROJ/project.pbxproj"
echo "			files = (" >> "$XCODEPROJ/project.pbxproj"
for file in "${!BUILDFILE_UUIDS[@]}"; do
    filename=$(basename "$file")
    echo "				${BUILDFILE_UUIDS[$file]} /* $filename in Sources */," >> "$XCODEPROJ/project.pbxproj"
done
echo "			);" >> "$XCODEPROJ/project.pbxproj"
echo "			runOnlyForDeploymentPostprocessing = 0;" >> "$XCODEPROJ/project.pbxproj"
echo "		};" >> "$XCODEPROJ/project.pbxproj"
echo "/* End PBXSourcesBuildPhase section */" >> "$XCODEPROJ/project.pbxproj"
echo "" >> "$XCODEPROJ/project.pbxproj"

# Add PBXTargetDependency section
echo "/* Begin PBXTargetDependency section */" >> "$XCODEPROJ/project.pbxproj"
echo "		$DEP_UUID /* PBXTargetDependency */ = {" >> "$XCODEPROJ/project.pbxproj"
echo "			isa = PBXTargetDependency;" >> "$XCODEPROJ/project.pbxproj"
echo "			target = $EXT_TARGET_UUID /* AI Orchestrator Extension */;" >> "$XCODEPROJ/project.pbxproj"
echo "			targetProxy = $PROXY_UUID /* PBXContainerItemProxy */;" >> "$XCODEPROJ/project.pbxproj"
echo "		};" >> "$XCODEPROJ/project.pbxproj"
echo "/* End PBXTargetDependency section */" >> "$XCODEPROJ/project.pbxproj"
echo "" >> "$XCODEPROJ/project.pbxproj"

# Add XCBuildConfiguration section
echo "/* Begin XCBuildConfiguration section */" >> "$XCODEPROJ/project.pbxproj"

# Project Debug config
cat >> "$XCODEPROJ/project.pbxproj" << EOF
		$PROJECT_BUILDCONFIG_DEBUG_UUID /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CODE_SIGN_IDENTITY = "-";
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				GCC_C_LANGUAGE_STANDARD = gnu11;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"\$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				MACOSX_DEPLOYMENT_TARGET = 13.0;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = macosx;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			};
			name = Debug;
		};
EOF

# Project Release config
cat >> "$XCODEPROJ/project.pbxproj" << EOF
		$PROJECT_BUILDCONFIG_RELEASE_UUID /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CODE_SIGN_IDENTITY = "-";
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				GCC_C_LANGUAGE_STANDARD = gnu11;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				MACOSX_DEPLOYMENT_TARGET = 13.0;
				MTL_ENABLE_DEBUG_INFO = NO;
				MTL_FAST_MATH = YES;
				SDKROOT = macosx;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_OPTIMIZATION_LEVEL = "-O";
			};
			name = Release;
		};
EOF

# Container app Debug config
cat >> "$XCODEPROJ/project.pbxproj" << EOF
		$CONTAINER_BUILDCONFIG_DEBUG_UUID /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				CODE_SIGN_ENTITLEMENTS = "";
				CODE_SIGN_IDENTITY = "-";
				CODE_SIGN_STYLE = Manual;
				COMBINE_HIDPI_IMAGES = YES;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				ENABLE_HARDENED_RUNTIME = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_NSMainStoryboardFile = "";
				INFOPLIST_KEY_NSPrincipalClass = NSApplication;
				LD_RUNPATH_SEARCH_PATHS = (
					"\$(inherited)",
					"@executable_path/../Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = "com.debuggerlab.ai-orchestrator";
				PRODUCT_NAME = "\$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
			};
			name = Debug;
		};
EOF

# Container app Release config
cat >> "$XCODEPROJ/project.pbxproj" << EOF
		$CONTAINER_BUILDCONFIG_RELEASE_UUID /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				CODE_SIGN_ENTITLEMENTS = "";
				CODE_SIGN_IDENTITY = "-";
				CODE_SIGN_STYLE = Manual;
				COMBINE_HIDPI_IMAGES = YES;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				ENABLE_HARDENED_RUNTIME = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_NSMainStoryboardFile = "";
				INFOPLIST_KEY_NSPrincipalClass = NSApplication;
				LD_RUNPATH_SEARCH_PATHS = (
					"\$(inherited)",
					"@executable_path/../Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = "com.debuggerlab.ai-orchestrator";
				PRODUCT_NAME = "\$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
			};
			name = Release;
		};
EOF

# Extension Debug config
cat >> "$XCODEPROJ/project.pbxproj" << EOF
		$EXT_BUILDCONFIG_DEBUG_UUID /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				CODE_SIGN_IDENTITY = "-";
				CODE_SIGN_STYLE = Manual;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_FILE = Resources/ExtensionInfo.plist;
				INFOPLIST_KEY_CFBundleDisplayName = "AI Orchestrator Extension";
				INFOPLIST_KEY_NSHumanReadableCopyright = "Copyright © 2026 DebuggerLab. All rights reserved.";
				LD_RUNPATH_SEARCH_PATHS = (
					"\$(inherited)",
					"@executable_path/../Frameworks",
					"@executable_path/../../../../Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = "com.debuggerlab.ai-orchestrator.extension";
				PRODUCT_NAME = "\$(TARGET_NAME)";
				SKIP_INSTALL = YES;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
			};
			name = Debug;
		};
EOF

# Extension Release config
cat >> "$XCODEPROJ/project.pbxproj" << EOF
		$EXT_BUILDCONFIG_RELEASE_UUID /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				CODE_SIGN_IDENTITY = "-";
				CODE_SIGN_STYLE = Manual;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_FILE = Resources/ExtensionInfo.plist;
				INFOPLIST_KEY_CFBundleDisplayName = "AI Orchestrator Extension";
				INFOPLIST_KEY_NSHumanReadableCopyright = "Copyright © 2026 DebuggerLab. All rights reserved.";
				LD_RUNPATH_SEARCH_PATHS = (
					"\$(inherited)",
					"@executable_path/../Frameworks",
					"@executable_path/../../../../Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = "com.debuggerlab.ai-orchestrator.extension";
				PRODUCT_NAME = "\$(TARGET_NAME)";
				SKIP_INSTALL = YES;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
			};
			name = Release;
		};
EOF

echo "/* End XCBuildConfiguration section */" >> "$XCODEPROJ/project.pbxproj"
echo "" >> "$XCODEPROJ/project.pbxproj"

# Add XCConfigurationList section
echo "/* Begin XCConfigurationList section */" >> "$XCODEPROJ/project.pbxproj"
cat >> "$XCODEPROJ/project.pbxproj" << EOF
		$PROJECT_CONFIGLIST_UUID /* Build configuration list for PBXProject "AIOrchestratorXcode" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				$PROJECT_BUILDCONFIG_DEBUG_UUID /* Debug */,
				$PROJECT_BUILDCONFIG_RELEASE_UUID /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		$CONTAINER_CONFIGLIST_UUID /* Build configuration list for PBXNativeTarget "AI Orchestrator" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				$CONTAINER_BUILDCONFIG_DEBUG_UUID /* Debug */,
				$CONTAINER_BUILDCONFIG_RELEASE_UUID /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		$EXT_CONFIGLIST_UUID /* Build configuration list for PBXNativeTarget "AI Orchestrator Extension" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				$EXT_BUILDCONFIG_DEBUG_UUID /* Debug */,
				$EXT_BUILDCONFIG_RELEASE_UUID /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
EOF
echo "/* End XCConfigurationList section */" >> "$XCODEPROJ/project.pbxproj"
echo "" >> "$XCODEPROJ/project.pbxproj"

# Close the pbxproj file
cat >> "$XCODEPROJ/project.pbxproj" << EOF
	};
	rootObject = $PROJECT_UUID /* Project object */;
}
EOF

# Create the extension Info.plist
mkdir -p "$PROJECT_DIR/Resources"
cat > "$PROJECT_DIR/Resources/ExtensionInfo.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>AI Orchestrator Extension</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>$(MARKETING_VERSION)</string>
    <key>CFBundleVersion</key>
    <string>$(CURRENT_PROJECT_VERSION)</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionAttributes</key>
        <dict>
            <key>XCSourceEditorCommandDefinitions</key>
            <array>
                <dict>
                    <key>XCSourceEditorCommandClassName</key>
                    <string>$(PRODUCT_MODULE_NAME).FixCodeCommand</string>
                    <key>XCSourceEditorCommandIdentifier</key>
                    <string>com.debuggerlab.ai-orchestrator-xcode.fix-code</string>
                    <key>XCSourceEditorCommandName</key>
                    <string>Fix Code Issues</string>
                </dict>
                <dict>
                    <key>XCSourceEditorCommandClassName</key>
                    <string>$(PRODUCT_MODULE_NAME).ExplainCodeCommand</string>
                    <key>XCSourceEditorCommandIdentifier</key>
                    <string>com.debuggerlab.ai-orchestrator-xcode.explain-code</string>
                    <key>XCSourceEditorCommandName</key>
                    <string>Explain Code</string>
                </dict>
                <dict>
                    <key>XCSourceEditorCommandClassName</key>
                    <string>$(PRODUCT_MODULE_NAME).RefactorCodeCommand</string>
                    <key>XCSourceEditorCommandIdentifier</key>
                    <string>com.debuggerlab.ai-orchestrator-xcode.refactor-code</string>
                    <key>XCSourceEditorCommandName</key>
                    <string>Refactor Code</string>
                </dict>
                <dict>
                    <key>XCSourceEditorCommandClassName</key>
                    <string>$(PRODUCT_MODULE_NAME).GenerateDocsCommand</string>
                    <key>XCSourceEditorCommandIdentifier</key>
                    <string>com.debuggerlab.ai-orchestrator-xcode.generate-docs</string>
                    <key>XCSourceEditorCommandName</key>
                    <string>Generate Documentation</string>
                </dict>
                <dict>
                    <key>XCSourceEditorCommandClassName</key>
                    <string>$(PRODUCT_MODULE_NAME).GenerateTestsCommand</string>
                    <key>XCSourceEditorCommandIdentifier</key>
                    <string>com.debuggerlab.ai-orchestrator-xcode.generate-tests</string>
                    <key>XCSourceEditorCommandName</key>
                    <string>Generate Tests</string>
                </dict>
                <dict>
                    <key>XCSourceEditorCommandClassName</key>
                    <string>$(PRODUCT_MODULE_NAME).BuildAndFixCommand</string>
                    <key>XCSourceEditorCommandIdentifier</key>
                    <string>com.debuggerlab.ai-orchestrator-xcode.build-and-fix</string>
                    <key>XCSourceEditorCommandName</key>
                    <string>Build and Fix</string>
                </dict>
            </array>
            <key>XCSourceEditorExtensionPrincipalClass</key>
            <string>$(PRODUCT_MODULE_NAME).SourceEditorExtension</string>
        </dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.dt.Xcode.extension.source-editor</string>
    </dict>
</dict>
</plist>
EOF

# Create xcscheme
mkdir -p "$XCODEPROJ/xcshareddata/xcschemes"
cat > "$XCODEPROJ/xcshareddata/xcschemes/AIOrchestratorXcode.xcscheme" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1500"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "$CONTAINER_TARGET_UUID"
               BuildableName = "AI Orchestrator.app"
               BlueprintName = "AI Orchestrator"
               ReferencedContainer = "container:AIOrchestratorXcode.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES"
      shouldAutocreateTestPlan = "YES">
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "$CONTAINER_TARGET_UUID"
            BuildableName = "AI Orchestrator.app"
            BlueprintName = "AI Orchestrator"
            ReferencedContainer = "container:AIOrchestratorXcode.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "$CONTAINER_TARGET_UUID"
            BuildableName = "AI Orchestrator.app"
            BlueprintName = "AI Orchestrator"
            ReferencedContainer = "container:AIOrchestratorXcode.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
EOF

echo "✓ Xcode project generated at: $XCODEPROJ"
echo ""
echo "To build the extension:"
echo "  cd $PROJECT_DIR"
echo "  ./Scripts/build.sh"

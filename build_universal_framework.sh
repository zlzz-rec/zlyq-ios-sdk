#!/bin/sh

# 运行脚本前，让xcode选择device的地方是generic iOS Device，否则打包出来的缺少arm7
cd `dirname $0`

# Framework 名称, 从第一个参数获取，如果没有参数，取文件夹名称做为名称，如果Framework名称和项目中的Target名称不一样的话，需要指定FRAMEWORK_NAME
FRAMEWORK_NAME=$1

if [[ $1 == '' ]]; then
    FRAMEWORK_NAME=${PWD##*/}
fi

# 项目路径
SRCROOT=$(cd "$(dirname "$0")";pwd)

# Framework 文件导出的路径
INSTALL_DIR=${SRCROOT}/Products/${FRAMEWORK_NAME}.framework

# workspace 文件路径
WORK_SPACE=${FRAMEWORK_NAME}.xcworkspace

# 编译过程中的临时文件路径
WORKING_DIR=${SRCROOT}/build

# 真机版本的Framework目录
DEVICE_WORKING_DIR=${WORKING_DIR}/device
DEVICE_DIR=${DEVICE_WORKING_DIR}/Build/Products/Release-iphoneos/${FRAMEWORK_NAME}.framework

# x86_64 版本的Framework目录
SIMULATOR_WORKING_DIR=${WORKING_DIR}/simulator
SIMULATOR_DIR=${SIMULATOR_WORKING_DIR}/Build/Products/Release-iphonesimulator/${FRAMEWORK_NAME}.framework

# xcodebuild 生成两个版本的 Framework
xcodebuild -workspace "${WORK_SPACE}" -scheme "${FRAMEWORK_NAME}" -derivedDataPath "${DEVICE_WORKING_DIR}" -sdk iphoneos -configuration "Release" clean build
xcodebuild -workspace "${WORK_SPACE}" -scheme "${FRAMEWORK_NAME}" -derivedDataPath "${SIMULATOR_WORKING_DIR}" -sdk iphonesimulator -configuration "Release" clean build

# 清除已经存在的老版本文件.
if [ -d "${INSTALL_DIR}" ]
then
rm -rf "${INSTALL_DIR}"
fi

# 创建导出目录
mkdir -p "${INSTALL_DIR}"

# 把真机Framework 文件拷贝导导出目录
cp -R "${DEVICE_DIR}/" "${INSTALL_DIR}/"

# 链接模拟器Framework
# Uses the Lipo Tool to merge both binary files ([arm_v7] [i386] [x86_64] [arm64]) into one Universal final product.
lipo -create "${DEVICE_DIR}/${FRAMEWORK_NAME}" "${SIMULATOR_DIR}/${FRAMEWORK_NAME}" -output "${INSTALL_DIR}/${FRAMEWORK_NAME}"
lipo -info ${INSTALL_DIR}/${FRAMEWORK_NAME}

# 清理过程文件
rm -r "${WORKING_DIR}"

# 打开导出文件所在目录
open "${INSTALL_DIR}"

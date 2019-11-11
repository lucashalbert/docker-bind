#!/bin/bash
bind_ver=${bind_ver:-$(curl "https://pkgs.alpinelinux.org/packages?name=bind&branch=edge&repo=main&arch=x86_64" | grep "text-success" | sed 's/<[^>]*>//g' | tr -d " ")}
build_date=${build_date:-$(date +"%Y%m%dT%H%M%S")}

for docker_arch in amd64 arm32v6 arm64v8; do
    case ${docker_arch} in
        amd64   ) qemu_arch="x86_64"  image_arch="amd64" s6_arch="amd64"   ;;
        arm32v6 ) qemu_arch="arm"     image_arch="arm"   s6_arch="arm"     ;;
        arm64v8 ) qemu_arch="aarch64" image_arch="arm64" s6_arch="aarch64" ;;    
    esac
    cp Dockerfile.cross Dockerfile.${docker_arch}
    sed -i "s|__BASEIMAGE_ARCH__|${docker_arch}|g" Dockerfile.${docker_arch}
    sed -i "s|__QEMU_ARCH__|${qemu_arch}|g" Dockerfile.${docker_arch}
    sed -i "s|__S6_ARCH__|${s6_arch}|g" Dockerfile.${docker_arch}
    sed -i "s|__BIND_VER__|${bind_ver}|g" Dockerfile.${docker_arch}
    sed -i "s|__BUILD_DATE__|${build_date}|g" Dockerfile.${docker_arch}
    if [ ${docker_arch} == 'amd64' ]; then
        sed -i "/__CROSS__/d" Dockerfile.${docker_arch}
        cp Dockerfile.${docker_arch} Dockerfile
    else
        sed -i "s/__CROSS__//g" Dockerfile.${docker_arch}
    fi


    # Check for qemu static bins
    if [[ ! -f qemu-${qemu_arch}-static ]]; then
        echo "Downloading the qemu static binaries for ${docker_arch}"
        wget -q -N https://github.com/multiarch/qemu-user-static/releases/download/v4.0.0-4/x86_64_qemu-${qemu_arch}-static.tar.gz
        tar -xvf x86_64_qemu-${qemu_arch}-static.tar.gz
        rm x86_64_qemu-${qemu_arch}-static.tar.gz
    fi

    # Build
    if [ "$EUID" -ne 0 ]; then
        sudo docker build -f Dockerfile.${docker_arch} -t lucashalbert/bind:${docker_arch}-${bind_ver} .
        sudo docker push lucashalbert/bind:${docker_arch}-${bind_ver}
    else
        docker build -f Dockerfile.${docker_arch} -t lucashalbert/bind:${docker_arch}-${bind_ver} .
        docker push lucashalbert/bind:${docker_arch}-${bind_ver}

        # Create and annotate arch/ver docker manifest
        DOCKER_CLI_EXPERIMENTAL=enabled docker manifest create lucashalbert/bind:${docker_arch}-${bind_ver} lucashalbert/bind:${docker_arch}-${bind_ver}
        DOCKER_CLI_EXPERIMENTAL=enabled docker manifest annotate lucashalbert/bind:${docker_arch}-${bind_ver} lucashalbert/bind:${docker_arch}-${bind_ver} --os linux --arch ${image_arch}
        DOCKER_CLI_EXPERIMENTAL=enabled docker manifest push lucashalbert/bind:${docker_arch}-${bind_ver}

    fi
done



# Create version specific docker manifest
DOCKER_CLI_EXPERIMENTAL=enabled docker manifest create lucashalbert/bind:${bind_ver} lucashalbert/bind:amd64-${bind_ver} lucashalbert/bind:arm32v6-${bind_ver} lucashalbert/bind:arm64v8-${bind_ver}

# Create latest docker manifest
DOCKER_CLI_EXPERIMENTAL=enabled docker manifest create lucashalbert/bind:latest lucashalbert/bind:amd64-${bind_ver} lucashalbert/bind:arm32v6-${bind_ver} lucashalbert/bind:arm64v8-${bind_ver}

for docker_arch in amd64 arm32v6 arm64v8; do
    case ${docker_arch} in
        amd64   ) image_arch="amd64" ;;
        arm32v6 ) image_arch="arm"   ;;
        arm64v8 ) image_arch="arm64" ;;    
    esac

    # Annotate version specific docker manifest
    DOCKER_CLI_EXPERIMENTAL=enabled docker manifest annotate lucashalbert/bind:${bind_ver} lucashalbert/bind:${docker_arch}-${bind_ver} --os linux --arch ${image_arch}

    # Annotate latest docker manifest
    DOCKER_CLI_EXPERIMENTAL=enabled docker manifest annotate lucashalbert/bind:latest lucashalbert/bind:${docker_arch}-${bind_ver} --os linux --arch ${image_arch}
done

# Push version specific docker manifest
DOCKER_CLI_EXPERIMENTAL=enabled docker manifest push lucashalbert/bind:${bind_ver}

# Push latest docker manifest
DOCKER_CLI_EXPERIMENTAL=enabled docker manifest push lucashalbert/bind:latest

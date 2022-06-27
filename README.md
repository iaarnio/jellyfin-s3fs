## General

Aim is to easily host Jellyfin media server with access to S3 bucket as data source.

Combines two docker contaners:

- [linuxserver/jellyfin] (https://hub.docker.com/r/linuxserver/jellyfin)

- [panubo/s3fs] (https://hub.docker.com/r/panubo/s3fs)

into a single container.

## Usage

```bash
docker run \
    --name=jellyfin-s3fs \
    -e AWS_STORAGE_BUCKET_NAME=$AWS_STORAGE_BUCKET_NAME \
    -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
    -e AWS_S3_MOUNTPOINT=$AWS_S3_MOUNTPOINT \
    -e AWS_REGION=$AWS_REGION \
    -e TZ=$TZ \
    -e PUID=1000 \
    -e PGID=1000 \
    -p 8096:8096 \
    --device /dev/fuse \
    --cap-add SYS_ADMIN \
    --restart unless-stopped \
    iaarnio/jellyfin-s3fs
```
Note: Some environments require also --privileged flag.

## Parameters related to S3FS

| Parameter | Function |
| :----: | --- |
| `-e AWS_STORAGE_BUCKET_NAME` | The S3 bucket name. E.g. myvideobucket |
| `-e AWS_ACCESS_KEY_ID` | The AWS user account name |
| `-e AWS_SECRET_ACCESS_KEY` | The AWS user account password |
| `-e AWS_S3_MOUNTPOINT=$AWS` | Where is file system S3 bucket will me mounted. E.g. /media |
| `-e AWS_REGION=$AWS_REGION` | The AWS region where S3 bucket is hosted. E.g. eu-north-1 |

## Parameters related to Jellyfin

Container images are configured using parameters passed at runtime (such as those above). These parameters are separated by a colon and indicate `<external>:<internal>` respectively. For example, `-p 8080:80` would expose port `80` from inside the container to be accessible from the host's IP on port `8080` outside the container.

| Parameter | Function |
| :----: | --- |
| `-p 8096` | Http webUI. |
| `-p 8920` | Optional - Https webUI (you need to set up your own certificate). |
| `-p 7359/udp` | Optional - Allows clients to discover Jellyfin on the local network. |
| `-p 1900/udp` | Optional - Service discovery used by DNLA and clients. |
| `-e PUID=1000` | for UserID - see below for explanation |
| `-e PGID=1000` | for GroupID - see below for explanation |
| `-e TZ=Europe/London` | Specify a timezone to use (e.g. Europe/London). |
| `-e JELLYFIN_PublishedServerUrl=192.168.0.5` | Set the autodiscovery response domain or IP address. |
| `-v /config` | Jellyfin data storage location. *This can grow very large, 50gb+ is likely for a large collection.* |
| `-v /data/tvshows` | Media goes here. Add as many as needed e.g. `/data/movies`, `/data/tv`, etc. |
| `-v /data/movies` | Media goes here. Add as many as needed e.g. `/data/movies`, `/data/tv`, etc. |

## Optional Parameters

The [official documentation for ports](https://jellyfin.org/docs/general/networking/index.html) has additional ports that can provide auto discovery.

Service Discovery (`1900/udp`) - Since client auto-discover would break if this option were configurable, you cannot change this in the settings at this time. DLNA also uses this port and is required to be in the local subnet.

Client Discovery (`7359/udp`) - Allows clients to discover Jellyfin on the local network. A broadcast message to this port with "Who is Jellyfin Server?" will get a JSON response that includes the server address, ID, and name.

```
  -p 7359:7359/udp \
  -p 1900:1900/udp \
```

The [official documentation for environmentals](https://jellyfin.org/docs/general/administration/configuration.html) has additional environmentals that can provide additional configurability such as migrating to the native Jellyfin image.

## User / Group Identifiers

When using volumes (`-v` flags) permissions issues can arise between the host OS and the container, we avoid this issue by allowing you to specify the user `PUID` and group `PGID`.

Ensure any volume directories on the host are owned by the same user you specify and any permissions issues will vanish like magic.

In this instance `PUID=1000` and `PGID=1000`, to find yours use `id user` as below:

```bash
  $ id username
    uid=1000(dockeruser) gid=1000(dockergroup) groups=1000(dockergroup)
```


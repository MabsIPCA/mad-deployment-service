FROM minio/minio AS mc-env

FROM minio/minio:RELEASE.2023-02-27T18-10-45Z.hotfix.6ba7e7dbf

COPY --from=mc-env /usr/bin/mc /usr/bin/mc
#! /usr/bin/env bash

# set up auth file
AWS_S3_AUTHFILE="/opt/s3fs/passwd-s3fs"
echo "${AWS_S3_ACCESS_KEY_ID}:${AWS_S3_SECRET_ACCESS_KEY}" > "${AWS_S3_AUTHFILE}"
chmod 600 "${AWS_S3_AUTHFILE}"

# mount s3 bucket
export AWS_S3_MOUNT=/home/blackstrap-user
S3FS_OPTS=${S3FS_OPTS:-"\
-o storage_class=intelligent_tiering \
-o use_cache=/tmp/s3fs \
-o del_cache \
-o multireq_max=100 \
-o multipart_size=5 \
-o parallel_count=10 \
-o max_dirty_data=50 \
-o listobjectsv2 \
-o complement_stat \
-o update_parent_dir_stat"}
s3fs ${S3FS_OPTS} \
    -o allow_other \
    -o passwd_file="${AWS_S3_AUTHFILE}" \
    -o url="${AWS_S3_URL:=https://s3.amazonaws.com}" \
    "${AWS_S3_BUCKET}" \
    "${AWS_S3_MOUNT}"

ls "${AWS_S3_MOUNT}"

# check if it worked
if healthcheck.sh; then
    echo "Mounted bucket ${AWS_S3_BUCKET} onto /home/blackstrap-user"
    exec "$@"
else
    echo "Mount failure"
fi

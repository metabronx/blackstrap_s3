#! /usr/bin/env bash

# set up auth file
echo "${AWS_S3_ACCESS_KEY_ID}:${AWS_S3_SECRET_ACCESS_KEY}" > "${AWS_S3_AUTHFILE}"
chmod 600 "${AWS_S3_AUTHFILE}"

# mount s3 bucket
S3FS_OPTS=${S3FS_OPTS:-"\
-o storage_class=intelligent_tiering \
-o use_cache=/tmp/s3fs \
-o del_cache \
-o multireq_max=100 \
-o streamupload \
-o max_thread_count=$(nproc) \
-o listobjectsv2 \
-o complement_stat \
-o update_parent_dir_stat"}
s3fs ${S3FS_OPTS} \
    -o allow_other \
    -o passwd_file="${AWS_S3_AUTHFILE}" \
    -o url="${AWS_S3_URL}" \
    "${AWS_S3_BUCKET}" \
    "${AWS_S3_MOUNT}"

ls "${AWS_S3_MOUNT}"

# check if it worked
if healthcheck.sh; then
    echo "Mounted bucket ${AWS_S3_BUCKET} onto ${AWS_S3_MOUNT}"
    exec "$@"
else
    echo "Mount failure"
fi

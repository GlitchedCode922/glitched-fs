#include <errno.h>
#include <glfs/glfs.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

int64_t read_block(void* fp, uint64_t block_number, void* buffer) {
    fseek(fp, block_number * GLFS_BLOCK_SIZE, SEEK_SET);
    size_t res = fread(buffer, GLFS_BLOCK_SIZE, 1, fp);
    if (res != 1) {
        if (ferror(fp)) {
            return -errno;
        } else {
            return -EIO;
        }
    }
    return res;
}

int64_t write_block(void* fp, uint64_t block_number, const void* buffer) {
    fseek(fp, block_number * GLFS_BLOCK_SIZE, SEEK_SET);
    size_t res = fwrite(buffer, GLFS_BLOCK_SIZE, 1, fp);
    if (res != 1) {
        if (ferror(fp)) {
            return -errno;
        } else {
            return -EIO;
        }
    }
    return res;
}

void glfs_sync(void* fp) {
    fflush(fp);
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <output_file>\n", argv[0]);
        return 1;
    }

    const char *output_file = argv[1];

    FILE *fp = fopen(output_file, "r+b");
    if (!fp) {
        perror("Failed to open output file");
        return 1;
    }

    glfs_backing_t backing = {
        .data = fp,
        .read_block = read_block,
        .write_block = write_block,
        .sync = glfs_sync,
        .alloc = malloc,
        .free = free,
    };

    fseek(fp, 0, SEEK_END);
    uint64_t size = ftell(fp);

    if (size < 19 * GLFS_BLOCK_SIZE) {
        fprintf(stderr, "Output file too small to create a filesystem\n");
        return -EINVAL;
    }

    int res = glfs_mkfs(&backing, size);
    if (res < 0) {
        errno = -res;
        perror("mkfs");
        fclose(fp);
        return 1;
    }

    fclose(fp);
    return 0;
}


```bash
cd secrets

docker run --rm -ti -v "$(pwd):/tmp/certs" -v "$(pwd)/output:/tmp/output" -w /tmp/certs alpine sh generate.sh
```
# docer-parser
just for fun


# how to run

This will parse source code in local folder `/src` and with file ext `.go`, then print out as html format.

```
$ cd && mkdir docker-src
$ cd docker-src
$ git clone https://github.com/docker/machine.git
$ git clone https://github.com/docker/docker.git

$ sudo docker run -v ~/docker-src:/src -e SRC=/src -e EXT=.go -e HTML=true liubin/docker-parser
```

where `/src` in the container should contains docker projects.



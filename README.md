# docker-ruby-pair-programming
Docker image for pair programing on ruby applications

Building the image:
Pass the user to the image so user inside the image has the same id as the outside user and share permissions
```
docker build --build-arg USER_UID=$(id -u) --build-arg USER_GID=$(id -g) --tag barrerajl/ruby-pair-programming
```


Usage:

```
#Rails example
  ruby-application:
    image: barrerajl/ruby-pair-programming #image name at build time
    ports:
      - "31022:22" #ssh for tmux and so on...
      - "33000:3000" #ports to publish
    environment:
      AUTHORIZED_GH_USERS: barrerajl,barrerajl,barrerajl #github users to authorize comma separated a,b,c
    volumes:
      - './rails_app:/home/developer/app' #map actual directory outside for keeping the code
      - 'vim_sessions:/home/developer/.homesick/repos/vim-dot-files/home/.vim/sessions'

volumes:
  vim_sessions:  {} #volume to save different vim sessions
```

How to connect to the image:
Use -A to use the agent forwarding capabilities
```
ssh -A -p 31022 developer@mydockerhost
```

This work is heavily inspired from https://github.com/dpetersen/dev-container-base and https://github.com/eLafo/docker-dev-env-base


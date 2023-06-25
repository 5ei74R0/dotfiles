### .config/zsh/local
Store your local zsh configuration files here. These files will be ignored by git.
These files are loaded by `sheldon`.

#### Rules
Your configuration files should be named with a trailing `.zsh` extension.
e.g., `zshenv.zsh`, `zshrc.zsh`, `alias.zsh`

If a configuration file is named with a trailing `.zsh.defer` extension, it will be targeted for deferred loading.

#### e.g., gpu configuration
```sh
## CUDA and cuDNN paths
export CUDA_HOME=/usr/local/cuda
export PATH=${CUDA_HOME}/bin:${PATH}
export LD_LIBRARY_PATH=${CUDA_HOME}/lib64:/usr/local/lib:${LD_LIBRARY_PATH}
```

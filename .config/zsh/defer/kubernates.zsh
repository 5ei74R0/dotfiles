# Kubernetes aliases and completions
if ! (( ${+functions[compdef]} )); then
    # Ensure compdef is loaded & block if already loaded
	autoload -Uz compinit && compinit
fi

alias k='kubectl'
alias kg='kubectl get'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgn='kubectl get nodes'
alias kga='kubectl get all'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias kaf='kubectl apply -f'
alias kdf='kubectl delete -f'
alias kc='kubectx'

kx() {
  if [ -z "$1" ]; then
    echo "Usage: kx <pod-name> [options] [-- command]"
    return 1
  fi

  # Get the first argument as the pod name
  local pod=$1
  shift # Remove $1 and keep the remaining arguments in $@

  # Employ user-specified command if provided
  if [[ "$*" == *"--"* ]]; then
    kubectl exec -it "$pod" "$@"
  else
    # By default, try /bin/bash, if it fails, try /bin/sh
    kubectl exec -it "$pod" "$@" -- /bin/bash || kubectl exec -it "$pod" "$@" -- /bin/sh
  fi
}

source <(command kubectl completion zsh)
compdef k=kubectl
compdef kg=kubectl
compdef kgp=kubectl
compdef kgs=kubectl
compdef kgn=kubectl
compdef kga=kubectl
compdef kd=kubectl
compdef kl=kubectl
compdef kaf=kubectl
compdef kdf=kubectl
compdef kc=kubectl

_kx() {
	emulate -L zsh

	local -a saved_words rest
	local saved_current
	saved_words=("${words[@]}")
	saved_current=$CURRENT

	rest=("${words[@]:2}")
	words=(kubectl exec -it "${rest[@]}" "")
	CURRENT=${#words}

	_kubectl

	words=("${saved_words[@]}")
	CURRENT=$saved_current
}
compdef _kx kx

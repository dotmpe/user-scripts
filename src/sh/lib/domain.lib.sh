#!/bin/sh


ssh_key_unlink() {
  (
    cd ~/.ssh
    for p in {config,id_rsa{,.pub}}; do
      [ -L "$p" ] && rm $p || error "Cannot remove $p";
    done
  )
}

ssh_key_link() {
  (
    cd ~/.ssh
    [ ! -e "id_rsa" -o -L "id_rsa" ] || {
      error "SSH key is not a symlink!"
      return
    }
    [ "$(readlink id_rsa)" = "$1-id_rsa" ] || {
      [ -f "$1-id_rsa" ] || {
        crit "No such key '$1'" 1
      }
      ssh_key_unlink;
      ln -s $1-id_rsa.pub id_rsa.pub;
      ln -s $1-id_rsa id_rsa;
      warn "SSH ID now '$1'"
    }
  )
}

ssh_config_link()
{
  (
    cd ~/.ssh
    [ ! -e "config" -o -L "config" ] || {
      error "SSH config is not a symlink!" 1
    }
    target=$HOME/.conf/ssh/$1.config
    [ -e "config" -a "$(readlink config)" = "$target" ] || {
      [ -f "$target" ] || {
        crit "No such SSH config '$1'" 1
      }
      test ! -e config || rm config
      ln -s $target config
    }
  )
}

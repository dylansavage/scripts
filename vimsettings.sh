#!/bin/bash

#  Check to see if sudo is root
if [ "$(id -u $SUDO_USER)" = 0 ] ; then
  	/usr/bin/echo "Do not run this as root. Used to install personal vim settings"
	exit
fi

#  Set home directory
myPath="/home/$SUDO_USER"

#  Install Yum packages
#  Add your desired repository into the package list to install
packageList="
	git
	vim-enhanced
	gcc
	epel-release
	python34
"

#  Will check whether the package in packageList exists on the system and will install if not
for package in $packageList
do
	if /usr/bin/rpm -qa | grep -q ^"$package"* ; then
		/usr/bin/echo "$package" is already installed
	else
		/usr/bin/echo "$package" is not installed yet
		yum -y install "$package"
	fi
done

#  install pip (based on ask.xmodulo.com/install-python3-centos.html)
if ! command -v pip &> /dev/null; then
	curl -O https://bootstrap.pypa.io/get-pip.py
	/usr/bin/python3.4 get-pip.py
	rm -f get-pip.py
else
	/usr/bin/echo "pip already is installed"
fi

#  Pathogen install
/usr/bin/mkdir -p $myPath/.vim/autoload $myPath/.vim/bundle

curl -LSso $myPath/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim
https://bootstrap.pypa.io/get-pip.py
python3.4 get-pip.py
rm -f get-pip.py



#  NERDTree install
if [ -z "$myPath"/.vim/bundle/nerdtree ]; then
	git clone https://github.com/scrooloose/nerdtree.git "$myPath"/.vim/bundle/nerdtree
	echo "nerdtree installation successful"
else
        echo "nerdtree already is installed"
fi

#  Modify local vimrc options (based on the faqs in github.com/scrooloose/nerdtree & gist.github.com/romainl/9970697)

echo -e "
\"  Starting pathogen
execute pathogen#infect()

\"  Setting mapleader to comma
let mapleader=\",\"

\"  Starting NERDTree automatically. Delete the below \" to toggle
\" autocmd vimenter * NERDTree

\"  Toggle NERDTree
map <Leader>n :NERDTreeToggle<CR>

\"  Closes NERDTree if its the only tab open
\" autocmd bufenter * if (winnr(\"$\") == 1 && exists(\"b:NERDTree\") && b:NERDTree.isTabTree()) | q | endif

\"  Maps ,t to open a new tab
cmap <Leader>t :tabe

\"  Maps split tabbing to ,hjkl
map <Leader>h <C-W><C-H>
map <Leader>j <C-W><C-J>
map <Leader>k <C-W><C-K>
map <Leader>l <C-W><C-L>

\" Maps ,w as a way to save as sudo
cmap w!! w !sudo tee % > /dev/null

filetype plugin indent on
syntax on
" > "$myPath"/.vimrc

# Create script to configure sudoedit at startup
echo "
	# Ensuring sudoedit uses local .vimrc

	EDITOR=vim
	VISUAL=\$EDITOR
	export EDITOR VISUAL

	# setting local aliases

" > /etc/profile.d/sudoedit_env.sh  

# Loads the sudoedit configs
source /etc/profile.d/sudoedit_env.sh
if [ $? = 0 ]; then
	/usr/bin/echo "Install was a success!"
fi

# Adds the sudoedit alias
cat > "$myPath"/.bash_aliases <<EOF
alias py=python3.6
alias se=sudoedit
alias pip=pip3.6
EOF

cat >> "$myPath"/.bash <<EOF
if [ -f ~/.bash_aliases ]; then
	. ~/.bash_aliases
fi
EOF

echo "Remember to source ~/.bash_aliases for alias use without restart"

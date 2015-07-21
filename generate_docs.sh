# Please do not run this script from any directory other than the git
# repository's root directory. Doing so will result in the documentation files
# being generated in a strange location.

if [ ! -d documentation ]; then
    echo "Creating documentation directory"
    mkdir documentation
else
    echo "Documentation directory exists"
fi

headerdoc2html -o documentation/ inTouch/
gatherheaderdoc documentation/

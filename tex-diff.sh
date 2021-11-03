#! /usr/bin/env bash
# Copy this script to the top level folder of your git repo
# TODO: Make it more flexible

# The location of the tex file that includes all chapters relative to the top level of the git repo.
MAIN_TEX=tex/main/thesis.tex
# Get the directory (i.e. the path without the *.tex file extension) using some regex magic
MAIN_DIR=${MAIN_TEX%/*}

# Output directory. This is where `diff.pdf` is copied to.
OUT_DIR=$PWD
# Directory that's used for storing the two commits
TMP_DIR=/tmp/thesis-diff
# Commit ID of the old commit
OLD_COMMIT=d998d06ca98430baf3bdfcf4d04f945833d06a2f
# Set variable to clean up afterwards
CLEANUP=

# Check if temp folder already exists
if [ -d "$TMP_DIR" ]; then
    # If so, remove everything
    rm -rf $TMP_DIR
fi

# Make empty tmp folder
mkdir $TMP_DIR

# Make folder structure
mkdir "$TMP_DIR/old"
mkdir "$TMP_DIR/new"

# Copy the two versions into the temp folder
git --work-tree="$TMP_DIR/old" checkout $OLD_COMMIT -- .
git --work-tree="$TMP_DIR/new" checkout HEAD -- .

# Make a third folder for the diff containing all the required files
cp -r "$TMP_DIR/new" "$TMP_DIR/diff"

# Make diff file in the same folder as MAIN_TEX such that relative inports work
DIFF_FILE="$TMP_DIR/diff/$MAIN_DIR/diff.tex"
# Run latexdiff and include all subfiles using --flatten option
# I like the CFONT option (new content is blue)
latexdiff -t CFONT --flatten "$TMP_DIR/old/$MAIN_TEX" "$TMP_DIR/new/$MAIN_TEX" > $DIFF_FILE

# But I don't want to have the lines that were deleted.
# Renew command for deleted content (i.e. don't show it)
OLD_CMD="\\\\providecommand{\\\\DIFdel}\\[1\\]{{\\\\protect\\\\color{red} \\\\scriptsize #1}}"
NEW_CMD="\\\\providecommand{\\\\DIFdel}\\[1\\]{}"
sed -i "s/$OLD_CMD/$NEW_CMD/" $DIFF_FILE

# Compile diff.tex
cd "$TMP_DIR/diff/$MAIN_DIR"
latexmk -pdf diff.tex

# And move to the output directory
cp "diff.pdf" "$OUT_DIR/diff.pdf"

# Clean up if needed
if [ $CLEANUP ]; then
    rm -rf $TMP_DIR
fi

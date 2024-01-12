#!/usr/bin/env bash

assert() {
    if [ $# -ne 3 ]; then
        echo 'Usage: assert args expected_exit_status expected_errorname'
        exit 1
    fi

    expected_exit_status="$1"
    expected_errorname="$2"
    args="$3"

    stdout=$(powershell.exe -C "..\dist\picturesize.exe $args" 2>&1)
    actual_exit_status=$?
    actual_errorname=$(echo "$stdout" | grep -oE '^.+Error')

    if [ -n "$actual_errorname" ] && [ $(echo "$stdout" | wc -l) -gt 1 ]; then
        echo ".\picturesize.exe $args => FAIL: got $actual_errorname, but exception handling not implemented"
        exit 1
    fi

    if [ "$actual_exit_status" = "$expected_exit_status" ] && [ "$actual_errorname" = "$expected_errorname" ]; then
        echo ".\picturesize.exe $args => PASS (exit status: $actual_exit_status, error name: $actual_errorname)"
    elif [ "$actual_exit_status" = "$expected_exit_status" ]; then
        echo ".\picturesize.exe $args => FAIL: $expected_errorname expected as an exit error, but got $actual_errorname"
        exit 1
    else
        echo ".\picturesize.exe $args => FAIL: $expected_exit_status expected as an exit status, but got $actual_exit_status"
        exit 1
    fi
}


cd test_files

# pass
assert 0 "" "get input.docx" 
assert 0 "" "apply -f config.jsonl -o output.docx input.docx" 

# help
assert 0 "" "-h"
assert 0 "" "get -h"
assert 0 "" "apply -h"

# invalid choice 
assert 1 "" "input.docx"

# required args
assert 1 "" ""
assert 1 "" "get"
assert 1 "" "apply"
assert 1 "" "apply -f config.jsonl input.docx"
assert 1 "" "apply -o output.docx input.docx"
assert 1 "" "apply -f config.jsonl -o output.docx"

# error handled
assert 1 FileNotFoundError "apply -f filenotexist.jsonl -o output.docx input.docx"
assert 1 PackageNotFoundError "get filenotexist.docx"
assert 1 PackageNotFoundError "apply -f config.jsonl -o output.docx filenotexist.docx"
assert 1 PackageNotFoundError "get formatnotdocx.docx"
assert 1 PackageNotFoundError "apply -f config.jsonl -o output.docx formatnotdocx.docx"
assert 1 ValueError "apply -f config.jsonl -o notdocx.doc input.docx"
assert 1 ValueError "apply -f config.jsonl -o notdocx input.docx"
assert 1 KeyError "apply -f wrongkey.jsonl -o output.docx input.docx"
assert 1 JSONDecodeError "apply -f badjson.jsonl -o output.docx input.docx"
assert 1 IndexError "apply -f badindex.jsonl -o output.docx input.docx"
assert 1 AttributeError "apply -f notpicture.jsonl -o output.docx input.docx"


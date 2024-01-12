import argparse
from docx import Document
from docx.opc.exceptions import PackageNotFoundError
import re
import json
from json.decoder import JSONDecodeError
import sys


def config_args():
    parser = argparse.ArgumentParser(description="get and set picture size in docx")

    # subcommand: get, apply
    subparsers = parser.add_subparsers(title="subcommands")

    # parser for get subcommand
    parser_get = subparsers.add_parser(
        "get", help="get picture size and print as standard output"
    )
    parser_get.add_argument("input", type=str, help="path to input docx")
    parser_get.set_defaults(func=get_parameters)

    # parser for apply subcommand
    parser_apply = subparsers.add_parser(
        "apply", help="apply picture size according to configuration"
    )
    parser_apply.add_argument(
        "-f", "--file", type=str, required=True, help="path to configuration"
    )
    parser_apply.add_argument(
        "-o", "--output", type=str, required=True, help="path to output docx"
    )
    parser_apply.add_argument("input", type=str, help="path to input docx")
    parser_apply.set_defaults(func=apply_parameters)

    return parser.parse_args()


def get_parameters(args):
    try:
        document = Document(args.input)
        for index, shape in enumerate(document.inline_shapes):
            if shape.type.name == "PICTURE":
                params = {
                    "index": index,
                    "width": shape.width,
                    "height": shape.height,
                }
                print(json.dumps(params))
        sys.exit(0)
    except FileNotFoundError as e:
        print("FileNotFoundError: {}".format(e), file=sys.stderr)
        sys.exit(1)
    except PackageNotFoundError as e:
        print("PackageNotFoundError: {}".format(e), file=sys.stderr)
        sys.exit(1)


def apply_parameters(args):
    if not re.match(r".+\.docx$", args.output):
        print("ValueError: output file is not docx", file=sys.stderr)
        sys.exit(1)
    try:
        document = Document(args.input)
        try:
            with open(args.file, mode="r") as reader:
                for line in reader:
                    params = json.loads(line)
                    index = params["index"]
                    shape = document.inline_shapes[index]
                    shape.width = params["width"]
                    shape.height = params["height"]
            document.save(args.output)
            sys.exit(0)
        except KeyError as e:
            print("KeyError: {}".format(e), file=sys.stderr)
            sys.exit(1)
    except FileNotFoundError as e:
        print("FileNotFoundError: {}".format(e), file=sys.stderr)
        sys.exit(1)
    except PackageNotFoundError as e:
        print("PackageNotFoundError: {}".format(e), file=sys.stderr)
        sys.exit(1)
    except KeyError as e:
        print(
            "KeyError: configration is not appropreate in key {}".format(e),
            file=sys.stderr,
        )
        sys.exit(1)
    except JSONDecodeError as e:
        print("JSONDecodeError: {}".format(e), file=sys.stderr)
        sys.exit(1)
    except IndexError:
        print(
            "IndexError: index in config not found in inline_shapes",
            file=sys.stderr,
        )
        sys.exit(1)
    except AttributeError:
        print("AttributeError: non picture shape not handled", file=sys.stderr)
        sys.exit(1)


def main():
    try:
        args = config_args()
        args.func(args)
    except AttributeError:
        print("usage: picturesize.py [-h] {get,apply} ...", file=sys.stderr)
        print(
            "picturesiz.py: error: the following arguments are required: input",
            file=sys.stderr,
        )
        sys.exit(1)


if __name__ == "__main__":
    main()

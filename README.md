
# Lexical Analyzer

implementation of the lexical analysis part of a C compiler. It uses Flex as the lexical analyser. It takes simple C code as input and print out the tokens. It was the second assignment of the course **CSE310, BUET**.


[Assignment Spec](https://github.com/TawhidMM/Lexical_Analyzer/blob/main/materilas/spec.pdf)

[Flex Lecture Material](https://github.com/TawhidMM/Lexical_Analyzer/blob/main/materilas/Lexical%20Analysis%20Lecture.pdf)


## Requirements

- **Flex :** a tool for tokenizing the input

## Installation
#### 1. update wsl/linux software packages
```bash
  sudo apt update
```
#### 2. install flex

```bash
  sudo apt install flex
```

## How to run

#### 1. put the c code **input.txt**

#### 2. run the shell script to generate the log and token file

```bash
  ./run.sh
```

## Related

The full CSE 310, BUET 
[Compiler](https://github.com/TawhidMM/C_Compiler)

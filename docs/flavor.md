
# Argument Flavor

Following are the flavor templates that can be selected. If the `flavor` argument is not provided then it will use the `CUSTOM` configurations which are present in var.tfvars file.

Flavors are listed as options when it is not used in the command as an argument. User can select either CUSTOM, large, medium or small as per the requirements.


## CUSTOM Flavor template
This is set in var.tfvars which can be considered for custom configurations

```
bastion                     = {memory      = "16",   processors  = "1",    "count"   = 1}
bootstrap                   = {memory      = "32",   processors  = "0.5",  "count"   = 1}
master                      = {memory      = "32",   processors  = "0.5",  "count"   = 3}
worker                      = {memory      = "32",   processors  = "0.5",  "count"   = 2}
```

## Small Configuration Template

```
bastion                     = {memory      = "16",   processors  = "0.5",  "count"   = 1}
bootstrap                   = {memory      = "32",   processors  = "0.5",  "count"   = 1}
master                      = {memory      = "32",   processors  = "0.5",  "count"   = 3}
worker                      = {memory      = "32",   processors  = "0.5",  "count"   = 2}
```

## Medium Configuration Template

```
bastion                     = {memory      = "16",   processors  = "1",    "count"   = 1}
bootstrap                   = {memory      = "32",   processors  = "0.5",  "count"   = 1}
master                      = {memory      = "32",   processors  = "0.5",  "count"   = 3}
worker                      = {memory      = "32",   processors  = "0.5",  "count"   = 3}
```

## Large Configuration Template

```
bastion                     = {memory      = "64",   processors  = "1.5",  "count"   = 1}
bootstrap                   = {memory      = "32",   processors  = "0.5",  "count"   = 1}
master                      = {memory      = "64",   processors  = "1.5",  "count"   = 3}
worker                      = {memory      = "64",   processors  = "1.5",  "count"   = 4}
```



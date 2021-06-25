# Create release

Ensure you have the [hub](https://github.com/github/hub) client installed


## Update VERSION in devel

- Update VERSION file
- Update VERSION string in openshift-install-powervs script

Create PR and get it merged

## Push changes from devel to master

```
git clone https://github.com/ocp-power-automation/openshift-install-power
git checkout master
git merge origin/devel
```
Verify all changes from devel are in master branch and then push the changes

```
git push origin master:master
```

## Create Release

```
cd release
./make_release -p tag
```
This will create a tag based on latest version in `VERSION` and make a release.

It'll also print the instructions to be followed to update the release notes.


#!/bin/bash

#Adapted from https://github.com/kata-containers/kata-containers/blob/main/tools/packaging/release/tag_repos.sh

set -o errexit
set -o nounset
set -o pipefail

hub_bin="hub"
hash_bin="sha256sum"
tmp_dir=$(mktemp -d -t tag-repos-tmp.XXXXXXXXXX)
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script_name="$(basename "${BASH_SOURCE[0]}")"
project_dir="$(dirname "${script_dir}")"
OWNER=${OWNER:-"ocp-power-automation"}
PROJECT="OpenShift UPI Install Helper for Power VS"
PUSH="${PUSH:-"false"}"
branch="master"
readonly URL_RAW_FILE="https://raw.githubusercontent.com/${OWNER}"
# This is set to the right value later.
version=""

function usage() {

	cat <<EOT
Usage: ${script_name} [options] <args>
This script creates a new release for ${PROJECT}.
It tags and create release for:
EOT
	for r in "${repos[@]}"; do
		echo "  - ${r}"
	done

	cat <<EOT

Args:
status : Get Current ${PROJECT} tags status
pre-release <target-version>:  Takes a version to check all the components match with it (but not the runtime)
tag    : Create tags for ${PROJECT}

Options:
-b <branch>: branch were will check the version.
-h         : Show this help
-p         : push tags

EOT

}

finish() {
	rm -rf "$tmp_dir"
}

trap finish EXIT

die() {
	echo >&2 "ERROR: $*"
	exit 1
}

info() {
	echo "INFO: $*"
}

repos=(
	"openshift-install-power"
)


do_tag(){
	local tag=${1:-}
	[ -n "${tag}" ] || die "No tag not provided"
	if git rev-parse -q --verify "refs/tags/${tag}"; then
		info "$repo already has tag"
	else
		info "Creating tag ${tag} for ${repo}"
		git tag -a "${tag}" -s -m "${PROJECT} release ${tag}"
	fi
}

tag_repos() {

	info "Creating tag ${version} in all repos"
	for repo in "${repos[@]}"; do
		git clone --quiet "https://github.com/${OWNER}/${repo}.git"
		pushd "${repo}" >>/dev/null
		git remote set-url --push origin "git@github.com:${OWNER}/${repo}.git"
		git fetch origin
		git checkout "${branch}"
		version_from_file=$(cat ./VERSION)
		info "Check VERSION file has ${version}"
		if [ "${version_from_file}" != "${version}" ];then
			die "mismatch: VERSION file (${version_from_file}) and runtime version ${version}"
		else
			echo "OK"
		fi
		git fetch origin --tags
		tag="$version"

		do_tag "${tag}"

		"${hash_bin}" ./openshift-install-powervs > "${project_dir}"/sha256sum.txt
		
		popd >>/dev/null
	done
}

push_tags() {
	info "Pushing tags to repos"
	for repo in "${repos[@]}"; do
		pushd "${repo}" >>/dev/null
		tag="$version"
		info "Push tag ${tag} for ${repo}"
		git push origin "${tag}"
		create_github_release "${PWD}" "${tag}"
		popd >>/dev/null
	done
}

create_github_release() {
	repo_dir=${1:-}
	tag=${2:-}
	[ -d "${repo_dir}" ] || die "No repository directory"
	[ -n "${tag}" ] || die "No tag specified"
	if ! "${hub_bin}" release show "${tag}"; then
		info "Creating Github release"
		if [[ "$tag" =~ "-rc" ]]; then
			rc_args="-p"
		fi
    	        rc_args=${rc_args:-}
		"${hub_bin}" -C "${repo_dir}" release create ${rc_args} -m "${PROJECT} ${tag}" "${tag}"

		#cd "${project_dir}"
		#"${hash_bin}" ./openshift-install-powervs > sha256sum.txt
		#cd -

		"${hub_bin}" release edit -a "${project_dir}"/sha256sum.txt -m "${PROJECT} ${tag}" "${tag}"

		echo "Create release notes by following these instructions"
		echo ""
		echo """${PROJECT}"" ""${tag}"" > notes.md"
		echo "git log --oneline <old_tag>..""$version"" >> notes.md"
		echo ""
		echo "Review and udpate the release notes"
		echo ""
		echo "${hub_bin} release edit -F notes.md ${tag}"
	else
		info "Github release already created"
	fi
}

main () {
	while getopts "b:hp" opt; do
		case $opt in
		b) branch="${OPTARG}" ;;
		h) usage && exit 0 ;;
		p) PUSH="true" ;;
		esac
	done
	shift $((OPTIND - 1))

	subcmd=${1:-""}
	shift || true
	version=$(curl -Ls "${URL_RAW_FILE}/openshift-install-power/${branch}/VERSION" | grep -v -P "^#")

	[ -z "${subcmd}" ] && usage && exit 0

	pushd "${tmp_dir}" >>/dev/null

	case "${subcmd}" in
	tag)
		tag_repos
		if [ "${PUSH}" == "true" ]; then
			push_tags
		else
			info "tags not pushed, use -p option to push the tags"
		fi
		;;
	*)
		usage && die "Invalid argument ${subcmd}"
		;;

	esac

	popd >>/dev/null
}
main "$@"

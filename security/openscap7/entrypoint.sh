#!/usr/bin/env bash
set -euo pipefail

PROFILE_NAMESPACE=org.ssgproject.content_profile
PROFILE_PREFIX="xccdf_${PROFILE_NAMESPACE}"

if [[ "$#" -lt 2 || "${1:-}" != "auto" && "${1:-}" != "manual" ]]; then
    echo "Run OpenSCAP on Docker RHEL 7 and CentOS 7 images"
    echo
    echo "There are 2 ways to use this tool:"
    echo "Automatic: Provide exactly 2 arguments: auto [imagename:tag]."
    echo "  e.g. 'auto centos:7'"
    echo "  The second argument is the image name/tag to evaluate."
    echo "  This will cause both XCCDF SSG profile and CVE evaluations to be completed."
    echo
    echo "  The SSG profile Id to use will be determined from the ${PROFILE_NAMESPACE} label"
    echo "  of the image being scanned."
    echo
    echo "  If a tailoring file matching the name template: ssg-OS-PROFILE-tailoring.xml"
    echo "  exists in the image being scanned, then it will be used to tailor the scan."
    echo
    echo "  Reports will be saved to the /workspace directory, mount a directory to that location"
    echo "  if you wish to retain them."
    echo
    echo "  Exit code will be 1 if there are fails in either SSG or CVE evaluation and 0 if none."
    echo
    echo "Manual: Provide a 'manual' argument, an image name to evaluate, then oscap parameters:"
    echo "  e.g. 'manual centos:7 oval eval /usr/share/xml/scap/ssg/content/ssg-rhel7-oval.xml'"
    echo "  If you want to reference tailoring files and/or reports you can mount an"
    echo "  additional directory and reference that in your command."
    echo
    echo "Notes:"
    echo "  Mount /var/run/docker.sock from the host to this container, (you should not need --privileged=true)."
    echo "  If you are scanning a remote image, you will need to pull the image on the host first."
    exit 1
fi

if [ -r "/var/run/docker.sock" ]; then
    echo "Mount /var/run/docker.sock from the host to this container, (you should not need --privileged=true)."
fi

# Will run an evaluation and calculate the number of fails.
# First argument should be the type of scan to run (ssg or cve)
# followed by arguments to pass to the oscap command.
# The return code will be: 0 (pass), 1 (results included fails),
# 2 (scan fail) or 3 (count fail).
autoeval() {
    local type="${1}"
    shift
    local args=("$@")

    local xml="/workspace/${type}-results-arf.xml"
    local report="--results-arf ${xml} --report /workspace/${type}-report.html"
    # Count any selected, applicable, checked, non-pass XCCDF results as fails:
    local fails='count(/arf:asset-report-collection/arf:reports/arf:report[@id="xccdf1"]/arf:content/cdf12:TestResult/cdf12:rule-result[not(cdf12:result="notselected") and not(cdf12:result="notapplicable") and not(cdf12:result="notchecked") and not(cdf12:result="pass")])'
    local ns=cdf12="http://checklists.nist.gov/xccdf/1.2"
    local count=1

    # We enable command echo for oscap and count commands for transparency/reproducibility
    # and disable exit on error, since we check each exit code explicitly.
    set -x +e
    # shellcheck disable=SC2086
    oscap-chroot /mnt xccdf eval ${report} "${args[@]}"
    local scan_exit=$?
    # shellcheck disable=SC2086
    count=$(xmlstarlet sel -N ${ns} -t -v "${fails}" ${xml})
    local count_exit=$?
    set +x -e

    if [ $scan_exit -eq 1 ]; then
        # Note that exit code 2 just means scan fails, which we catch below.
        echo "Scan failed for ${type}"
        return 2
    fi
    if [ $count_exit -ne 0 ]; then
        echo "Count failed for ${type}"
        return 3
    fi
    if [ $scan_exit -eq 2 ] || [ "$count" != "0" ]; then
        echo "Fails for ${type} evaluation: ${count}"
        return 1
    fi
    echo "All evaluations for ${type} passed"
    return 0
}

MODE="$1"
IMAGE="$2"
cd /tmp
echo "Unpacking the image"
docker-companion unpack "${IMAGE}" /mnt

if [ "${MODE}" == "auto" ]; then
    echo "Running automatic evaluations"
    if [ ! -d "/workspace" ]; then
        mkdir /workspace
    fi

    echo "Running SSG evaluation"
    OS=rhel7
    if [ -f "/mnt/etc/centos-release" ]; then
        OS=centos7
    fi
    PROFILE=$(docker inspect --format "{{ index .Config.Labels \"${PROFILE_NAMESPACE}\"}}" "${IMAGE}")
    if [[ "${PROFILE}" == "" ]]; then
        echo "Image does not contain an \"${PROFILE_NAMESPACE}\" label indicating the profile to use."
        exit 10
    fi
    TAILORING=
    TAILORING_FILE="/mnt/var/lib/scap/ssg/content/ssg-${OS}-${PROFILE}-tailoring.xml"
    echo "Looking for image tailoring file ${TAILORING_FILE}"
    if [ -r "${TAILORING_FILE}" ]; then
        echo "Using image tailoring file ${TAILORING_FILE}"
        TAILORING="--tailoring-file ${TAILORING_FILE}"
    fi
    # shellcheck disable=SC2206
    ARGS=('ssg' '--fetch-remote-resources' '--profile' "${PROFILE_PREFIX}_${PROFILE}" ${TAILORING} "/usr/share/xml/scap/ssg/content/ssg-${OS}-ds.xml")
    SSG=1
    if autoeval "${ARGS[@]}"; then
        SSG=0
    fi

    echo "Fetching latest CVE content"
    curl -Ls https://www.redhat.com/security/data/oval/com.redhat.rhsa-RHEL7.xml.bz2 | bzip2 -d -c > com.redhat.rhsa-all.xml
    curl -Ls -o com.redhat.rhsa-all.xccdf.xml https://www.redhat.com/security/data/metrics/com.redhat.rhsa-all.xccdf.xml
    echo "Running CVE evaluation"
    ARGS=('cve' 'com.redhat.rhsa-all.xccdf.xml')
    CVE=1
    if autoeval "${ARGS[@]}"; then
        CVE=0
    fi

    if [ $SSG -eq 0 ] && [ $CVE -eq 0 ]; then
        echo "Both SSG and CVE evaluations passed"
        exit 0
    fi
    echo "One or more evaluations failed"
    exit 1
else
    echo "Running manual evaluations"
    shift 2
    # We enable command echo for all oscap commands for transparency/reproducibility
    set -x
    oscap-chroot /mnt "$@"
    set +x
fi
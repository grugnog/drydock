#!/usr/bin/env bash
set -eo pipefail

if [ "$1" == "" ]; then
    echo "This is a utility to quickly generate tailoring files for specific OSs & Profiles."
    echo "NOTE: This is an interim approach only - tailoring content should be generated"
    echo "from documentation that explains the rationale behind each decision."
    echo
    echo "Pass the OS matching the SSG content file name for the scan you"
    echo "are parsing as the first argument (e.g centos7)."
    echo "Pass the profile matching the scan you as the second argument (e.g ospp)."
    exit 1
fi
if [ ! -r "out/ssg-results-arf.xml" ]; then
    echo "A file containing the false positive results you want to tailor named 'out/ssg-results-arf.xml' should be present "
    exit 2
fi

export FILE=ssg-$1-$2_baseline-tailoring.xml
echo '<?xml version="1.0" encoding="UTF-8"?>' > "${FILE}"
# shellcheck disable=SC2129
echo '<xccdf:Tailoring xmlns:xccdf="http://checklists.nist.gov/xccdf/1.2" id="xccdf_scap-workbench_tailoring_default">' >> "${FILE}"
echo "  <xccdf:benchmark href=\"/usr/share/xml/scap/ssg/content/ssg-$1-ds.xml\"/>" >> "${FILE}"
echo '  <xccdf:version time="2018-09-27T11:56:47">1</xccdf:version>' >> "${FILE}"
echo "  <xccdf:Profile id=\"xccdf_org.ssgproject.content_profile_$2_baseline\" extends=\"xccdf_org.ssgproject.content_profile_$2\">" >> "${FILE}"
echo "    <xccdf:title xmlns:xhtml=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en-US\" override=\"true\">$1 $2 Baseline Tailored</xccdf:title>" >> "${FILE}"
echo '    <xccdf:description xmlns:xhtml="http://www.w3.org/1999/xhtml" xml:lang="en-US" override="true"></xccdf:description>' >> "${FILE}"

xmlstarlet sel -N cdf12="http://checklists.nist.gov/xccdf/1.2" -t -v '/arf:asset-report-collection/arf:reports/arf:report[@id="xccdf1"]/arf:content/cdf12:TestResult/cdf12:rule-result[not(cdf12:result="notselected") and not(cdf12:result="notapplicable") and not(cdf12:result="notchecked") and not(cdf12:result="pass")]/@idref' out/ssg-results-arf.xml | sed -e 's/^/    <xccdf:select idref="/' -e 's/$/" selected="false"\/>/' >> "${FILE}"

echo >> "${FILE}"
echo '  </xccdf:Profile>' >> "${FILE}"
echo '</xccdf:Tailoring>' >> "${FILE}"
echo "Tailoring file '${FILE}' created."
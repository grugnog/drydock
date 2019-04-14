ARG SOURCE=registry.access.redhat.com/rhel7
# hadolint ignore=DL3006
FROM $SOURCE

# Set the OpenSCAP target profile label and env automated scans.
ARG SCAP_TARGET=stig-rhel7-disa
ARG TAILORING_SUFFIX=_baseline
LABEL org.ssgproject.content_profile=${SCAP_TARGET}${TAILORING_SUFFIX}
COPY ssg-*.xml /var/lib/scap/ssg/content/

# Complete an initial SSG automatic remediation
ENV PACKAGES openscap-utils scap-security-guide
RUN yum install -y ${PACKAGES} \
  && [ -f "/etc/centos-release" ] && OS=centos7 || OS=rhel7 \
  && oscap xccdf eval --remediate --fetch-remote-resources --profile "xccdf_org.ssgproject.content_profile_${SCAP_TARGET}" "/usr/share/xml/scap/ssg/content/ssg-${OS}-ds.xml" || true \
  && yum remove -y ${PACKAGES} \
  && yum clean all \
  && rm -rf /var/cache/yum
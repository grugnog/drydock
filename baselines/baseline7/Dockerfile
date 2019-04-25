ARG SOURCE=registry.access.redhat.com/rhel7
# hadolint ignore=DL3006
FROM $SOURCE

# Set the OpenSCAP target profile label and env automated scans.
ARG SCAP_TARGET=stig-rhel7-disa
ARG TAILORING_SUFFIX=_baseline
LABEL org.ssgproject.content_profile=${SCAP_TARGET}${TAILORING_SUFFIX}
COPY ssg-*.xml /var/lib/scap/ssg/content/

# Copy in helper scripts, to enable RHEL license (without storing licence to build)
# and run an initial OpenSCAP automatic remediation.
COPY scripts /usr/local/drydock
ENV PATH "${PATH}:/usr/local/drydock"

RUN chmod u+x /usr/local/drydock/* \
  # Complete an initial SSG automatic remediation
  && openscap-harden

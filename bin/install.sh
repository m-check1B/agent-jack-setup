#!/bin/bash
# agent-jack-setup INSTALL (macOS): retired (KRA-10893). One doctor now installs, repairs and checks a Mac.
# It lives in the public onboarding repo; this file only points there, so no second installer drifts from it.
echo "bin/install.sh is retired on macOS. Run the Agent Jack doctor instead (it installs, repairs and checks everything):"
echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/m-check1B/onboarding/main/agent-jack/doctor.sh)"'
exit 3

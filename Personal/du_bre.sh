# Variables
SOURCEDIR=~/DU
OUTDIR=~/DU/out/target/product
UPLOADDIR=~/shared/.bre
DEVICE=angler
# Special build type
export DU_BUILD_TYPE=BREYANA
# Start tracking time
START=$(date +%s)
# Change to the source directory
cd ${SOURCEDIR}
# Sync source
repo sync
# Initialize build environment
. build/envsetup.sh
# Clean out directory
make clobber
# Make angler
brunch ${DEVICE}
# Remove exisiting files
rm ${UPLOADDIR}/*_${DEVICE}_*.zip
rm ${UPLOADDIR}/*_${DEVICE}_*.zip.md5sum
# Copy new files
mv ${OUTDIR}/${DEVICE}/DU_${DEVICE}_*.zip ${UPLOADDIR}
mv ${OUTDIR}/${DEVICE}/DU_${DEVICE}_*.zip.md5sum ${UPLOADDIR}
# Upload files
. ~/upload.sh
# Clean out directory
make clobber
# Go back home
cd ~/
# Set build type back to what it was
export DU_BUILD_TYPE=CHANCELLOR
# Success! Stop tracking time
END=$(date +%s)
echo "====================================="
echo "Compilation and upload successful!"
echo "Total time elapsed: $(echo $(($END-$START)) | awk '{print int($1/60)"mins "int($1%60)"secs"}')"
echo "====================================="
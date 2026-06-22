// soundtouch_config.h - Build configuration for TranscriberAG
//
// This file configures SoundTouch to use 16-bit integer samples,
// matching the audio pipeline expectations of TranscriberAG.

#ifndef SOUNDTOUCH_CONFIG_H
#define SOUNDTOUCH_CONFIG_H

// Use 16-bit integer samples (matching TranscriberAG's MediumFrame)
#define SOUNDTOUCH_INTEGER_SAMPLES 1

#endif

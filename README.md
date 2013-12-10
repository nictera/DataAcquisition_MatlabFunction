DataAcquisition_MatlabFunction
===============

This legacy code is provided for those of you who would like an inexpensive way to acquire tetrode data. 
You may modify it as you wish (see LICENSE). It requires matlab and the Data Acquisition Toolbox.
Getting it to work on your particular system may be problematic due to incompatibilities in the parent application, 
OS, and/or NI card.

This daq6.m function was used to acquire data for several neuroscience papers, including:

Identification of single neurons in a forebrain network.
Day NF, Kerrigan SJ, Aoki N, Nick TA.
J Neurophysiol. 2011 Dec;106(6):3205-15

Directed functional connectivity matures with motor learning in a cortical pattern generator.
Day NF, Terleski KL, Nykamp DQ, Nick TA.
J Neurophysiol. 2013 Feb;109(4):913-23

Rhythmic cortical neurons increase their oscillations and sculpt basal ganglia signaling during motor learning.
Day NF, Nick TA.
Dev Neurobiol. 2013 Oct;73(10):754-68

Please see these papers for a relatively inexpensive amplifier, etc to use with this code.

This code was run on Matlab 2007b 32-bit on a 32-bit Windows PC.  It is likely that it will, at present (Dec 2013),
not run on a 64-bit machine,due to Matlab-NationalInstruments incompatibilities.

The program assumes an NI PCI-6251 card and a NeuroNexus A16 Probe.

tetread.m, a plotting function, is provided so that you can view your data and also see how to get it out of the data*.txt file.
tetread is a bit slow to start, so give it time.







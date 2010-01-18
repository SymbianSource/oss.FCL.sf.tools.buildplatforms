#
# Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
# All rights reserved.
# This component and the accompanying materials are made available
# under the terms of "Eclipse Public License v1.0"
# which accompanies this distribution, and is available
# at the URL "http://www.eclipse.org/legal/epl-v10.html".
#
# Initial Contributors:
# Nokia Corporation - initial contribution.
#
# Contributors:
#
# Description:
#
# buildpreparation's actual configuration export makefile

MAKEFILE =	/sf/tools/buildplatforms/build/config/export.mk
$(call push,MAKEFILE_STACK,$(MAKEFILE))

S60BUILDTOOLFILES =				$(MAKEFILEDIR)../tools/toucher.exe																			/epoc32/tools/ \
													$(MAKEFILEDIR)../tools/zip.exe																					/epoc32/tools/ \
													$(MAKEFILEDIR)../tools/S60_build.cmd																		/epoc32/tools/ \
													$(MAKEFILEDIR)../tools/localised_emu.pl																	/epoc32/tools/ \
													$(MAKEFILEDIR)../tools/build_tbs.cmd																		/epoc32/tools/s60tools/ \
													$(MAKEFILEDIR)../tools/gencmd.pl																				/epoc32/tools/s60tools/ \
													$(MAKEFILEDIR)../tools/targets_from_mmp.pl															/epoc32/tools/s60tools/ \
													$(MAKEFILEDIR)../tools/build_Variant.cmd																/epoc32/tools/s60tools/ \
													$(MAKEFILEDIR)../tools/sw_version.pl																		/epoc32/tools/s60tools/ \
													$(MAKEFILEDIR)../tools/parse_what_log.pl																/epoc32/tools/s60tools/ \
													$(MAKEFILEDIR)../tools/check_filename_uniq.pl														/epoc32/tools/ \
													$(MAKEFILEDIR)../tools/check_path_lenghts.pl														/epoc32/tools/ \
													$(MAKEFILEDIR)../tools/add_build_definition_filter.pl										/epoc32/tools/s60tools/

PRODUCTIZATIONFILES =			$(MAKEFILEDIR)../tools/check_environment.pl															/epoc32/tools/

S60BUILDDATAFILES =				$(MAKEFILEDIR)../data/S60_SystemBuild.xml																/epoc32/tools/s60tools/ \
													$(MAKEFILEDIR)../data/S60_SystemModel.xml																/epoc32/tools/s60tools/ \
													$(MAKEFILEDIR)../data/systemDefinitionLayerRef.xml											/epoc32/tools/s60tools/ \
													$(MAKEFILEDIR)../data/custom_SystemDefinition.xml												/epoc32/tools/s60tools/ \
													$(MAKEFILEDIR)../data/s60_sbs_config.xml																/epoc32/sbs_config/

STYLESYSTEMDEFFILES =			$(MAKEFILEDIR)../data/default_build.xml																	/epoc32/tools/systemDefinition/ \
													$(MAKEFILEDIR)../data/default_clean.xml																	/epoc32/tools/systemDefinition/ \
													$(MAKEFILEDIR)../data/systemDefinition.dtd															/epoc32/tools/systemDefinition/ \
													$(MAKEFILEDIR)../data/targetDefinition.xml															/epoc32/tools/systemDefinition/


buildpreparation_config										:: buildpreparation_config-s60buildtool buildpreparation_config-productization buildpreparation_config-s60builddata buildpreparation_config-stylesystemdef
buildpreparation_config-s60buildtool 			::
buildpreparation_config-productization  	::
buildpreparation_config-s60builddata 			::
buildpreparation_config-stylesystemdef		::


$(call addfiles, $(S60BUILDTOOLFILES), buildpreparation_config-s60buildtool)
$(call addfiles, $(PRODUCTIZATIONFILES), buildpreparation_config-productization)
$(call addfiles, $(S60BUILDDATAFILES), buildpreparation_config-s60builddata)
$(call addfiles, $(STYLESYSTEMDEFFILES), buildpreparation_config-stylesystemdef)

$(call popout,MAKEFILE_STACK)
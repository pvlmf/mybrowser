// Copyright 2020 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/**
 * @fileoverview This file holds dependencies that are deliberately excluded
 * from the main app.js module, to force them to load after other app.js
 * dependencies. This is done to improve performance of initial rendering of
 * core elements of the landing page, by delaying loading of non-core
 * elements (either not visible by default or not as performance critical).
 */

import './action_chips/action_chips.js';
import './action_chips/action_chips_proxy.js';
import './iframe.js';
import './lens_upload_dialog.js';
import './ntp_promo/individual_promos.js';
import './ntp_promo/ntp_promo_proxy.js';
import './voice_search_overlay.js';
import 'chrome://resources/cr_components/most_visited/most_visited.js';
import 'chrome://resources/cr_components/composebox/composebox.js';
import 'chrome://resources/cr_elements/cr_button/cr_button.js';
import 'chrome://resources/cr_elements/cr_toast/cr_toast.js';

export {CustomizeButtonsElement} from 'chrome://new-tab-page/shared/customize_buttons/customize_buttons.js';
export type {ComposeboxFuseboxActionRequest} from 'chrome://resources/cr_components/composebox/common.js';
export {ComposeboxElement, SubmitButtonIconType, VoiceSearchAction} from 'chrome://resources/cr_components/composebox/composebox.js';
export {ComposeboxProxyImpl} from 'chrome://resources/cr_components/composebox/composebox_proxy.js';
export {ThreadsRailElement} from 'chrome://resources/cr_components/composebox/threads_rail.js';
export {WindowProxy as ComposeboxWindowProxy} from 'chrome://resources/cr_components/composebox/window_proxy.js';
export {PageImageServiceBrowserProxy} from 'chrome://resources/cr_components/page_image_service/browser_proxy.js';
export {MojoPluralStringProxy as NTPPluralStringProxyImpl} from 'chrome://resources/cr_components/search/mojo_plural_string_proxy.js';
export {CrButtonElement} from 'chrome://resources/cr_elements/cr_button/cr_button.js';
export {CrToastElement} from 'chrome://resources/cr_elements/cr_toast/cr_toast.js';
export type {ActionChipClickDetail} from './action_chips/action_chips.js';
export {ActionChipsElement, ActionChipsRetrievalState} from './action_chips/action_chips.js';
export {ActionChipsApiProxyImpl} from './action_chips/action_chips_proxy.js';
export {IframeElement} from './iframe.js';
export {LensErrorType, LensFormElement, LensSubmitType} from './lens_form.js';
export {LensUploadDialogAction, LensUploadDialogElement, LensUploadDialogError} from './lens_upload_dialog.js';
export {NtpComposeboxElement} from './ntp_composebox.js';
export {IndividualPromosElement} from './ntp_promo/individual_promos.js';
export {NtpPromoProxyImpl} from './ntp_promo/ntp_promo_proxy.js';
export type {NtpPromoProxy} from './ntp_promo/ntp_promo_proxy.js';
export {VoiceSearchOverlayElement} from './voice_search_overlay.js';

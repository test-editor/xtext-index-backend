/*******************************************************************************
 * Copyright (c) 2012 - 2017 Signal Iduna Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * Contributors:
 * Signal Iduna Corporation - initial API and implementation
 * akquinet AG
 * itemis AG
 *******************************************************************************/

package org.testeditor.web.xtext.index.resources

import com.fasterxml.jackson.databind.JsonNode
import org.eclipse.xtend.lib.annotations.Data

/**
 * Repository Event (unifying different sources e.g. GitHub, Bitbucket etc.)
 */
@Data
class RepoEvent {

	String userid
	JsonNode nativeEventPayload

}

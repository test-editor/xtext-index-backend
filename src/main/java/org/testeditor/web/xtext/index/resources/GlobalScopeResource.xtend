package org.testeditor.web.xtext.index.resources

import java.io.IOException
import javax.ws.rs.Consumes
import javax.ws.rs.POST
import javax.ws.rs.Path
import javax.ws.rs.Produces
import javax.ws.rs.QueryParam
import javax.ws.rs.core.MediaType
import javax.ws.rs.core.Response
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtext.resource.impl.ResourceSetBasedResourceDescriptions
import org.eclipse.xtext.scoping.IGlobalScopeProvider
import org.eclipse.xtext.util.StringInputStream
import org.slf4j.LoggerFactory
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl
import javax.ws.rs.client.Entity

@Path("/xtext/index/global-scope")
@Produces(MediaType.APPLICATION_JSON)
class GlobalScopeResource implements IGlobalScopeResource {

	protected static val logger = LoggerFactory.getLogger(GlobalScopeResource)

	val IGlobalScopeProvider globalScopeProvider
	val ResourceSetBasedResourceDescriptions index

	new(IGlobalScopeProvider globalScopeProvider, ResourceSetBasedResourceDescriptions index) {
		this.globalScopeProvider = globalScopeProvider
		this.index = index
	}

	@POST
	@Consumes("text/plain")
	@Produces("application/json")
	override Response getScope(String context, @QueryParam("contentType") String contentType,
		@QueryParam("contextURI") String contextURI, @QueryParam("reference") String eReferenceURIString) {
		try {
			val eReference = createEReference(eReferenceURIString)
			val resource = createContextResource(context, contextURI, contentType)
			
			logger.debug('''Delegating to global scope provider («globalScopeProvider.class.simpleName»)''')
			val scope = globalScopeProvider.getScope(resource, eReference, null).allElements
//			logger.debug('''Global scope provider returned the following elements: «scope.forEach[name]»''')
			logger.debug('''Global scope provider returned the following elements: «scope.map[name].join(',')»''')
			
			return Response.ok(scope.toList).build

		} catch(GlobalScopeResourceException e) {
			return Response.serverError().entity(e).build
		}
	}

	private def createContextResource(String context, String contextURI, String contentType) {
		logger.debug('''Trying to retrieve or create context resource (type: «contentType», URI: «contextURI»''')
		val resourceSet = new ResourceSetImpl//tryToAccessIndexResourceSet
		val resource = tryToGetOrCreateResource(resourceSet, contextURI, contentType)
		if(context !== null && context != "") {
			tryToLoadResource(resource, context)
		}
		return resource
	}

	private def tryToAccessIndexResourceSet() {
		if(index !== null && index.resourceSet !== null) {
			return index.resourceSet
		} else {
			throw new IndexUnavailableException(
			'''Could not retrieve resource set from index «IF index === null»(index unavailable)«ENDIF»''')
		}
	}

	private def tryToGetOrCreateResource(ResourceSet resourceSet, String contextURI, String contentType) {
		try {
			if(contextURI !== null) {
				val uri = URI.createURI(contextURI)
				var resource = resourceSet.getResource(uri, false)
				if(resource === null) {
					resource = resourceSet.createResource(uri, contentType)
				}
				if(resource !== null) {
					return resource

				} else {
					throw new ResourceCreationException('''Failed to create resource for URI '«contextURI»' of type '«contentType»'.''')
				}
			} else {
				throw new InvalidContextURI('''No context URI was provided (URI is null).''')
			}
		} catch(IllegalArgumentException e) {
			throw new InvalidContextURI('''Provided context URI is invalid: «contextURI»''', e)
		}
	}

	private def tryToLoadResource(Resource resource, String context) {
		try {
			resource.load(new StringInputStream(context), emptyMap)
		} catch(IOException e) {
			logger.
				warn('''Failed to load provided content into resource «IF (resource !== null)»(URI: «resource.URI»)«ELSE» (resource is null!)«ENDIF»''')
		}

	}

	private def createEReference(String eReferenceURIString) {
		logger.debug('''Trying to instantiate EReference from URI string: «eReferenceURIString»''')
		val eReferenceURI = tryToCreateURI(eReferenceURIString)
		val baseURIString = eReferenceURI.trimFragment().toString()
		val ePackage = tryToRetrieveEPackage(baseURIString)

		return tryToLoadEReferenceFromEPackageResource(ePackage, eReferenceURI)
	}

	private def tryToCreateURI(String eReferenceURIString) {
		try {
			return URI.createURI(eReferenceURIString)
		} catch(IllegalArgumentException e) {
			throw new InvalidEReferenceException('''Provided EReference URI is invalid: «eReferenceURIString»''', e)
		}
	}

	private def tryToRetrieveEPackage(String baseURIString) {
		val ePackage = EPackage.Registry.INSTANCE.getEPackage(baseURIString)

		if(ePackage === null) {
			throw new InvalidEReferenceException('''Failed to load EPackage for URI: «baseURIString»''')
		} else if(ePackage.eResource === null) {
			throw new InvalidEReferenceException('''Containing resource for EPackage not found (URI: «baseURIString»)''')
		} else {
			return ePackage
		}
	}

	private def tryToLoadEReferenceFromEPackageResource(EPackage ePackage, URI eReferenceURI) {
		if(eReferenceURI.hasFragment) {
			val eReference = ePackage.eResource.getEObject(eReferenceURI.fragment) as EReference
			logger.debug('''Successfully instantiated EReference: «eReference.name» («eReference.EReferenceType.name»)''')
			return eReference
		} else {
			throw new InvalidEReferenceException('''Provided EReference URI does not point at concrete EObject (fragment is missing): «eReferenceURI.toString»''')
		}
	}

}

class GlobalScopeResourceException extends RuntimeException {
	new(String message, Throwable cause) {
		super(message, cause)
	}

	new(String message) {
		super(message)
	}
}

class InvalidContextURI extends GlobalScopeResourceException {

	new(String message, Throwable cause) {
		super(message, cause)
	}

	new(String message) {
		super(message)
	}

}

class InvalidEReferenceException extends GlobalScopeResourceException {

	new(String message, Throwable cause) {
		super(message, cause)
	}

	new(String message) {
		super(message)
	}

}

class IndexUnavailableException extends GlobalScopeResourceException {

	new(String message) {
		super(message)
	}
}

class ResourceCreationException extends GlobalScopeResourceException {

	new(String message) {
		super(message)
	}

}

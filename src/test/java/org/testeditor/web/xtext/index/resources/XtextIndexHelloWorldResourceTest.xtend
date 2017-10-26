package org.testeditor.web.xtext.index.resources

import io.dropwizard.testing.junit.ResourceTestRule
import org.junit.ClassRule
import org.junit.Test
import org.testeditor.web.xtext.index.api.Saying

import static org.assertj.core.api.Assertions.assertThat

class XtextIndexHelloWorldResourceTest {

	@ClassRule public static val resources = ResourceTestRule.builder
		.addResource(new XtextIndexHelloWorldResource("Hello, %s!", "Stranger"))
		.build

	@Test def void shouldRespondWithPersonalizedGreeting() {
		// given
		val name = "Arthur Dent"
		val expected = new Saying(42, '''Hello, «name»!''')

		// when
		val actual = resources.target("/xtext/index/hello-world")
			.queryParam("name", name).request.get(Saying)

		//then
		assertThat(actual.content).isEqualTo(expected.content)
	}
}

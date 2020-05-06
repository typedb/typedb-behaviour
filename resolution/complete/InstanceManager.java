package grakn.verification.resolution.complete;

import grakn.client.GraknClient.Transaction;
import grakn.client.GraknClient.Session;
import grakn.client.answer.ConceptMap;
import grakn.client.concept.thing.Thing;
import graql.lang.Graql;
import graql.lang.query.GraqlGet;

import java.util.stream.Collectors;
import java.util.stream.Stream;

public class InstanceManager {
    public static void enforceAllInstancesHaveKeys(Session session) {
        Transaction tx = session.transaction().read();

        GraqlGet instancesQuery = Graql.match(Graql.var("x").isa("thing"),
                Graql.not(Graql.var("x").isa("@has-attribute")),
                Graql.not(Graql.var("x").isa("@key-attribute")),
                Graql.not(Graql.var("x").isa("attribute"))
        ).get();
        Stream<ConceptMap> answers = tx.stream(instancesQuery);

        answers.forEach(ans -> {
            Thing<?, ?> thing = ans.get("x").asThing();
            if (thing.asRemote(tx).keys().collect(Collectors.toSet()).isEmpty()) {
                throw new RuntimeException(String.format("A Thing without a key was found, of type %s", thing.type().label().toString()));
            }
        });
        tx.close();
    }
}

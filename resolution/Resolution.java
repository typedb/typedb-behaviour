package grakn.verification.resolution;

import grakn.client.GraknClient;
import grakn.client.GraknClient.Session;
import grakn.client.GraknClient.Transaction;
import grakn.client.answer.ConceptMap;
import graql.lang.Graql;
import graql.lang.query.GraqlGet;

import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;

import static grakn.verification.resolution.common.Utils.loadGqlFile;

public class Resolution {

    private static Path SCHEMA_PATH = Paths.get("/Users/jamesfletcher/programming/verification/resolution/cases/case1/schema.gql");
    private static Path DATA_PATH = Paths.get("/Users/jamesfletcher/programming/verification/resolution/cases/case1/data.gql");


    public static void main(String[] args) {
        String graknHostUri = "localhost:48555";
        String graknKeyspace = "case1";

        String inferenceQuery = "match $ar isa area, has name $ar-name; $cont isa continent, has name $cont-name; $lh(location-hierarchy_superior: $cont, location-hierarchy_subordinate: $ar) isa location-hierarchy; get;";

        GraknClient grakn = new GraknClient(graknHostUri);

        try (Session session = grakn.session(graknKeyspace)) {
            try {
                // Load a schema incl. rules
                loadGqlFile(session, SCHEMA_PATH);
                // Load data
                loadGqlFile(session, DATA_PATH);
            } catch (IOException e) {
                e.printStackTrace();
                System.exit(1);
            }

            try (Transaction tx = session.transaction().read()) {
                List<ConceptMap> answers = tx.execute((GraqlGet) Graql.parse(inferenceQuery));
                for (ConceptMap answer : answers) {
                    List<ConceptMap> explainable = answer.explanation().getAnswers();
                }
            }
        }
    }
}

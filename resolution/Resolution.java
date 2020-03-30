package grakn.verification.resolution;

import grakn.client.GraknClient;
import grakn.client.GraknClient.Session;
import grakn.client.GraknClient.Transaction;
import grakn.client.answer.ConceptMap;
import grakn.verification.resolution.complete.Completer;
import grakn.verification.resolution.complete.SchemaManager;
import grakn.verification.resolution.resolve.QueryBuilder;
import graql.lang.Graql;
import graql.lang.query.GraqlGet;

import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;

import static grakn.verification.resolution.common.Utils.loadGqlFile;

public class Resolution {

    private static final String GRAKN_URI = "localhost:48555";
    private static final String COMPLETE_KEYSPACE = "complete";
    private static final String TEST_KEYSPACE = "test";
    private static GraknClient graknClient;
    private final Path schemaPath;
    private final Path dataPath;
    private Session completeSession;
    private Session testSession;

    public static void main(String[] args) {
        Path schemaPath = Paths.get("resolution", "test", "cases", "case2", "schema.gql").toAbsolutePath();
        Path dataPath = Paths.get("resolution", "test", "cases", "case2", "data.gql").toAbsolutePath();
        GraqlGet inferenceQuery = Graql.parse("match $transaction has currency $currency; get;").asGet();

        Resolution resolution_test = new Resolution(schemaPath, dataPath);
        resolution_test.testQuery(inferenceQuery);
        resolution_test.close();
    }

    private Resolution(Path schemaPath, Path dataPath) {
        this.schemaPath = schemaPath;
        this.dataPath = dataPath;
        graknClient = new GraknClient(GRAKN_URI);

        testSession = graknClient.session(TEST_KEYSPACE);
        completeSession = graknClient.session(COMPLETE_KEYSPACE);

        initialiseKeyspace(testSession);
        initialiseKeyspace(completeSession);

        // TODO Check that nothing in the given schema conflicts with the resolution schema
        // TODO Also check that all of the data in the initial data given has keys/ is uniquely identifiable

//        // Complete the KB-complete
//        Completer.complete(completeSession); // Should read the rules, undefine them, add the completion schema
//
//        SchemaManager completeSchemaManager = new SchemaManager(completeSession);
//
//        Completer completer = new Completer(completeSession);
//
//        SchemaManager.addResolutionSchema(completeSession);
//        try (Transaction tx = completeSession.transaction().read()) {
//            completer.loadRules(SchemaManager.getRules(tx));
//        }
//        SchemaManager.deleteRules(completeSession);
//
//        completer.complete();
    }

    private void close() {
        completeSession.close();
        testSession.close();
    }

    private void testQuery(GraqlGet inferenceQuery) {
        QueryBuilder rb = new QueryBuilder();
        List<GraqlGet> queries;

        try (Transaction tx = testSession.transaction().read()) {
            queries = rb.buildMatchGet(tx, inferenceQuery);
        }

        try (Transaction tx = completeSession.transaction().read()) {
            for (GraqlGet query: queries) {
                checkResolution(tx, query);
            }
        }
    }

    private void checkResolution(Transaction tx, GraqlGet query) {
        List<ConceptMap> answerStream = tx.execute(query);
        if (answerStream.size() != 1) {
            String msg = String.format("Resolution query had %d answers, it should have had 1. The query is:\n %s", answerStream.size(), query);
            throw new RuntimeException(msg);
        }
    }

    private void initialiseKeyspace(Session session) {
        try {
            // Load a schema incl. rules
            loadGqlFile(session, schemaPath);
            // Load data
            loadGqlFile(session, dataPath);
        } catch (IOException e) {
            e.printStackTrace();
            System.exit(1);
        }
    }
}

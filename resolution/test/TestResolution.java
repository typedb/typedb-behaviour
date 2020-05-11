package grakn.verification.resolution.test;

import grakn.verification.resolution.Resolution;
import graql.lang.Graql;
import graql.lang.query.GraqlGet;
import org.junit.AfterClass;
import org.junit.BeforeClass;
import org.junit.Test;

import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.concurrent.TimeoutException;

public class TestResolution {

    private static final String GRAKN_URI = "localhost:48555";
    private static GraknForTest graknForTest;

    @BeforeClass
    public static void beforeClass() throws InterruptedException, IOException, TimeoutException {
        Path graknArchive = Paths.get("external", "graknlabs_grakn_core", "grakn-core-all-linux.tar.gz");
        graknForTest = new GraknForTest(graknArchive);
        graknForTest.start();
    }

    @AfterClass
    public static void afterClass() throws InterruptedException, IOException, TimeoutException {
        graknForTest.stop();
    }

    @Test
    public void testCase1HappyPath() {
        Path schemaPath = Paths.get("resolution", "test", "cases", "case1", "schema.gql").toAbsolutePath();
        Path dataPath = Paths.get("resolution", "test", "cases", "case1", "data.gql").toAbsolutePath();
        GraqlGet inferenceQuery = Graql.parse("" +
                "match $lh (location-hierarchy_superior: $continent, " +
                "location-hierarchy_subordinate: $area) isa location-hierarchy; " +
                "$continent isa continent; " +
                "$area isa area; get;").asGet();

        Resolution resolution_test = new Resolution(GRAKN_URI, schemaPath, dataPath);
        resolution_test.testQuery(inferenceQuery);
        resolution_test.testCompleteness();
        resolution_test.close();
    }

    @Test
    public void testCase2HappyPath() {
        Path schemaPath = Paths.get("resolution", "test", "cases", "case2", "schema.gql").toAbsolutePath();
        Path dataPath = Paths.get("resolution", "test", "cases", "case2", "data.gql").toAbsolutePath();
        GraqlGet inferenceQuery = Graql.parse("match $transaction has currency $currency; get;").asGet();

        Resolution resolution_test = new Resolution(GRAKN_URI, schemaPath, dataPath);
        resolution_test.testQuery(inferenceQuery);
        resolution_test.testCompleteness();
        resolution_test.close();
    }

    @Test
    public void testCase3HappyPath() {
        Path schemaPath = Paths.get("resolution", "test", "cases", "case3", "schema.gql").toAbsolutePath();
        Path dataPath = Paths.get("resolution", "test", "cases", "case3", "data.gql").toAbsolutePath();
        GraqlGet inferenceQuery = Graql.parse("match (sibling: $p, sibling: $p1) isa siblingship; $p != $p1; get;").asGet();

        Resolution resolution_test = new Resolution(GRAKN_URI, schemaPath, dataPath);
        resolution_test.testQuery(inferenceQuery);
        resolution_test.testCompleteness();
        resolution_test.close();
    }

    @Test
    public void testCase4HappyPath() {
        Path schemaPath = Paths.get("resolution", "test", "cases", "case4", "schema.gql").toAbsolutePath();
        Path dataPath = Paths.get("resolution", "test", "cases", "case4", "data.gql").toAbsolutePath();
        GraqlGet inferenceQuery = Graql.parse("match $com isa company, has is-liable $lia; get;").asGet();

        Resolution resolution_test = new Resolution(GRAKN_URI, schemaPath, dataPath);
        resolution_test.testQuery(inferenceQuery);
        resolution_test.testCompleteness();
        resolution_test.close();
    }

    @Test
    public void testCase5HappyPath() {
        Path schemaPath = Paths.get("resolution", "test", "cases", "case5", "schema.gql").toAbsolutePath();
        Path dataPath = Paths.get("resolution", "test", "cases", "case5", "data.gql").toAbsolutePath();
        GraqlGet inferenceQuery = Graql.parse("match $c isa company, has name $n; get;").asGet();

        Resolution resolution_test = new Resolution(GRAKN_URI, schemaPath, dataPath);
        resolution_test.testQuery(inferenceQuery);
        resolution_test.testCompleteness();
        resolution_test.close();
    }
}


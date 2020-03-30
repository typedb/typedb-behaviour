package grakn.verification.resolution.complete;

import grakn.client.GraknClient;
import grakn.client.GraknClient.Transaction;
import grakn.client.answer.ConceptMap;
import grakn.client.concept.Concept;
import grakn.verification.resolution.resolve.QueryBuilder;
import graql.lang.Graql;
import graql.lang.pattern.Conjunction;
import graql.lang.pattern.Disjunction;
import graql.lang.pattern.Pattern;
import graql.lang.query.GraqlGet;
import graql.lang.query.GraqlInsert;
import graql.lang.statement.Statement;
import graql.lang.statement.Variable;

import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Stream;

import static grakn.verification.resolution.resolve.QueryBuilder.generateKeyStatements;
import static grakn.verification.resolution.resolve.QueryBuilder.makeAnonVarsExplicit;

public class Completer {

    private final GraknClient.Session session;
    private Set<Rule> rules;

    public Completer(GraknClient.Session session) {
        this.session = session;
    }

    public void complete() {
        boolean allRulesRerun = true;

        while (allRulesRerun) {
            allRulesRerun = false;
            try (GraknClient.Transaction tx = session.transaction().write()) {

                for (Rule rule : rules) {
                    List<ConceptMap> answers = tx.execute(rule.matchInsertQuery());
                    if (answers.size() > 0) {
                        allRulesRerun = true;
                    }
//                    allRulesRerun = allRulesRerun | completeRule(tx, rule);
                }
                tx.commit();
            }
        }
    }

//    public static boolean completeRule(Transaction tx, Rule rule) {
//        boolean allRulesRerun = false;
////        Stream<ConceptMap> answerStream = tx.stream(rule.matchQuery());
//        List<ConceptMap> answers = tx.execute(rule.matchQuery());
//        Iterator<ConceptMap> it = answers.iterator();
//
////        if (answers.size() > 0) {
//        if (it.hasNext()) {
//            allRulesRerun = true;
//
//
//            it.forEachRemaining(answer -> {
////                                ConceptMap answer = it.next();
//                        tx.execute(rule.matchInsertQuery(answer.map()));
////                                allRulesRerun = true;
////                        ruleRerun = true;
//                    }
//            );
//        }
//        return allRulesRerun;
//    }

    public void loadRules(Set<grakn.client.concept.Rule> graknRules) {
        Set<Rule> rules = new HashSet<>();
        for (grakn.client.concept.Rule graknRule : graknRules) {
            rules.add(new Rule(Objects.requireNonNull(graknRule.when()), Objects.requireNonNull(graknRule.then()), graknRule.label().toString()));
        }
        this.rules = rules;
    }

    private class Rule {
        private final Pattern when;
        private final Pattern then;
        private final String label;
        private final Disjunction<Pattern> dis;
        private Pattern conjInferenceStatementsThen;

        Rule(Pattern when, Pattern then, String label) {
            this.when = QueryBuilder.makeAnonVarsExplicit(when);
            this.then = QueryBuilder.makeAnonVarsExplicit(then);
            this.label = label;
            QueryBuilder qb = new QueryBuilder();
            Set<Statement> inferenceStatements = qb.inferenceStatements(this.when.statements(), this.then.statements(), this.label);

            HashSet<Pattern> h = new HashSet<>();
            h.add(new Conjunction<>(inferenceStatements));
            h.add(this.then);
            conjInferenceStatementsThen = new Conjunction<>(h);

            HashSet<Pattern> h2 = new HashSet<>();
            h2.add(Graql.not(conjInferenceStatementsThen));
            h2.add(Graql.not(this.then));

            dis = new Disjunction<>(h2);
        }

//        GraqlGet matchQuery() {
//            return Graql.match(when, Graql.not(this.then)).get().limit(1); // when; not {inference statements; then;}
//        }

        GraqlInsert matchInsertQuery() {
            return Graql.match(when, Graql.not(conjInferenceStatementsThen)).insert(conjInferenceStatementsThen.statements());
        }
//        GraqlInsert matchInsertQuery(Map<Variable, Concept> matchAnswerMap) {
//            Set<Statement> keyStatements = generateKeyStatements(matchAnswerMap);
//            Conjunction<Statement> keyPattern = new Conjunction<>(keyStatements);
//            return Graql.match(when, keyPattern).insert(conjInferenceStatementsThen.statements()); // when; keys; insert inference statements; then;
//        }

        String label() {
            return label;
        }
    }
}

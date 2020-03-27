package grakn.verification.resolution.common;

import graql.lang.statement.Statement;

import java.util.LinkedHashMap;

public class StatementContainer extends LinkedHashMap<String, Statement> {

    private char baseVar;

    public StatementContainer(char baseVar) {
        this.baseVar = baseVar;
    }

    public String getNextVar() {
        return Character.toString(baseVar) + size();
    }

//    public Statement put(String var, Statement statement) {
    public Statement put(Statement statement) {
        return super.put(getNextVar(), statement);
    }
}

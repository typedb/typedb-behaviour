/*
* Copyright (C) 2020 Grakn Labs
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 */

package grakn.verification.tools.integrity;

import grakn.client.GraknClient;
import graql.lang.Graql;
import org.junit.After;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;

import java.util.UUID;

import static org.junit.Assert.assertTrue;

public class ValidatorIT {


    private static GraknClient client;
    GraknClient.Session session;

    @BeforeClass
    public static void setup() {
        client = new GraknClient("localhost:48555");
    }

    @Before
    public void openSession() {
        String randomKeyspace = "ksp_" + (UUID.randomUUID()).toString().replace("-", "_").substring(10);
        session = client.session(randomKeyspace);
        loadSchema(session);
    }

    public void loadSchema(GraknClient.Session session) {
        try (GraknClient.Transaction tx = session.transaction().write()) {
            tx.execute(Graql.parse("define " +
                    "person sub entity, has name, plays employee, plays employer;" +
                    "company sub entity, key email, plays employer;" +
                    "employment sub relation, relates employer, relates employee;" +
                    "name sub attribute, value string;" +
                    "email sub attribute, value string, regex \".+@.+\\.com\" ;").asDefine());
            tx.commit();
        }
    }

    @After
    public void closeSession() {
        session.close();
    }

    @Test
    public void validatorReturnsStatus() {
        Validator validator = new Validator(session);
        assertTrue(validator.validate());
    }
}

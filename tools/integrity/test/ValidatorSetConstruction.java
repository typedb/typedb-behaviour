/*
 * GRAKN.AI - THE KNOWLEDGE GRAPH
 * Copyright (C) 2019 Grakn Labs Ltd
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
import grakn.client.concept.Label;
import grakn.client.concept.SchemaConcept;
import grakn.common.util.Pair;
import grakn.verification.tools.integrity.schema.Sub;
import grakn.verification.tools.integrity.schema.SubTrans;
import grakn.verification.tools.integrity.schema.Types;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.ExpectedException;

import java.util.Arrays;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertThat;
import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.atLeast;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Test the top level behaviors of the Validator
 */
public class ValidatorSetConstruction {
    @Rule
    public final ExpectedException exception = ExpectedException.none();

    @Test
    public void transitiveSubIsBuiltCorrectly() {
        Sub semanticSub = new Sub();
        SchemaConcept mockSchemaConcept0 = mock(SchemaConcept.class);
        when(mockSchemaConcept0.label()).thenReturn(Label.of("z"));
        SchemaConcept mockSchemaConcept1 = mock(SchemaConcept.class);
        when(mockSchemaConcept1.label()).thenReturn(Label.of("a"));
        SchemaConcept mockSchemaConcept2 = mock(SchemaConcept.class);
        when(mockSchemaConcept2.label()).thenReturn(Label.of("b"));
        SchemaConcept mockSchemaConcept3 = mock(SchemaConcept.class);
        when(mockSchemaConcept3.label()).thenReturn(Label.of("c"));
        SchemaConcept mockSchemaConcept4 = mock(SchemaConcept.class);
        when(mockSchemaConcept4.label()).thenReturn(Label.of("d"));
        SchemaConcept mockSchemaConcept5 = mock(SchemaConcept.class);
        when(mockSchemaConcept5.label()).thenReturn(Label.of("entity"));
        SchemaConcept mockSchemaConcept6 = mock(SchemaConcept.class);
        when(mockSchemaConcept6.label()).thenReturn(Label.of("relation"));
        SchemaConcept mockSchemaConcept7 = mock(SchemaConcept.class);
        when(mockSchemaConcept7.label()).thenReturn(Label.of("attribute"));
        SchemaConcept mockSchemaConcept8 = mock(SchemaConcept.class);
        when(mockSchemaConcept8.label()).thenReturn(Label.of("thing"));

        Type type0 = new Type(mockSchemaConcept0);
        Type type1 = new Type(mockSchemaConcept1);
        Type type2 = new Type(mockSchemaConcept2);
        Type type3 = new Type(mockSchemaConcept3);
        Type type4 = new Type(mockSchemaConcept4);
        Type type5 = new Type(mockSchemaConcept5);
        Type type6 = new Type(mockSchemaConcept6);
        Type type7 = new Type(mockSchemaConcept7);
        Type type8 = new Type(mockSchemaConcept8);

        Pair<Type, Type> sub1 = new Pair<>(type0, type1);
        Pair<Type, Type> sub2 = new Pair<>(type1, type2);
        Pair<Type, Type> sub3 = new Pair<>(type2, type5);
        Pair<Type, Type> sub4 = new Pair<>(type3, type6);
        Pair<Type, Type> sub5 = new Pair<>(type4, type6);
        // meta schema subtyping
        Pair<Type, Type> sub6 = new Pair<>(type5, type8);
        Pair<Type, Type> sub7 = new Pair<>(type6, type8);
        Pair<Type, Type> sub8 = new Pair<>(type7, type8);

        semanticSub.add(sub1);
        semanticSub.add(sub2);
        semanticSub.add(sub3);
        semanticSub.add(sub4);
        semanticSub.add(sub5);
        semanticSub.add(sub6);
        semanticSub.add(sub7);
        semanticSub.add(sub8);

        GraknClient.Session mockSession = mock(GraknClient.Session.class);
        Validator validator = new Validator(mockSession);

        // this should not error
        SubTrans transitiveSub = validator.createAndValidateTransitiveSubWithoutIdentity(semanticSub);
        assertNotNull(transitiveSub);
    }

    @Test
    public void entityRelationAttributeSetsAreBuiltCorrectly() {
        Sub semanticSub = new Sub();
        SchemaConcept mockSchemaConcept0 = mock(SchemaConcept.class);
        when(mockSchemaConcept0.label()).thenReturn(Label.of("z"));
        SchemaConcept mockSchemaConcept1 = mock(SchemaConcept.class);
        when(mockSchemaConcept1.label()).thenReturn(Label.of("a"));
        SchemaConcept mockSchemaConcept2 = mock(SchemaConcept.class);
        when(mockSchemaConcept2.label()).thenReturn(Label.of("b"));
        SchemaConcept mockSchemaConcept3 = mock(SchemaConcept.class);
        when(mockSchemaConcept3.label()).thenReturn(Label.of("c"));
        SchemaConcept mockSchemaConcept4 = mock(SchemaConcept.class);
        when(mockSchemaConcept4.label()).thenReturn(Label.of("d"));
        SchemaConcept mockSchemaConcept5 = mock(SchemaConcept.class);
        when(mockSchemaConcept5.label()).thenReturn(Label.of("entity"));
        SchemaConcept mockSchemaConcept6 = mock(SchemaConcept.class);
        when(mockSchemaConcept6.label()).thenReturn(Label.of("relation"));
        SchemaConcept mockSchemaConcept7 = mock(SchemaConcept.class);
        when(mockSchemaConcept7.label()).thenReturn(Label.of("attribute"));
        SchemaConcept mockSchemaConcept8 = mock(SchemaConcept.class);
        when(mockSchemaConcept8.label()).thenReturn(Label.of("thing"));

        Type type0 = new Type(mockSchemaConcept0);
        Type type1 = new Type(mockSchemaConcept1);
        Type type2 = new Type(mockSchemaConcept2);
        Type type3 = new Type(mockSchemaConcept3);
        Type type4 = new Type(mockSchemaConcept4);
        Type type5 = new Type(mockSchemaConcept5);
        Type type6 = new Type(mockSchemaConcept6);
        Type type7 = new Type(mockSchemaConcept7);
        Type type8 = new Type(mockSchemaConcept8);

        Pair<Type, Type> sub1 = new Pair<>(type0, type1);
        Pair<Type, Type> sub2 = new Pair<>(type1, type2);
        Pair<Type, Type> sub3 = new Pair<>(type2, type5);
        Pair<Type, Type> sub4 = new Pair<>(type3, type6);
        Pair<Type, Type> sub5 = new Pair<>(type4, type6);
        // meta schema subtyping
        Pair<Type, Type> sub6 = new Pair<>(type5, type8);
        Pair<Type, Type> sub7 = new Pair<>(type6, type8);
        Pair<Type, Type> sub8 = new Pair<>(type7, type8);

        semanticSub.add(sub1);
        semanticSub.add(sub2);
        semanticSub.add(sub3);
        semanticSub.add(sub4);
        semanticSub.add(sub5);
        semanticSub.add(sub6);
        semanticSub.add(sub7);
        semanticSub.add(sub8);

        GraknClient.Session mockSession = mock(GraknClient.Session.class);
        Validator validator = new Validator(mockSession);

        // this should not error
        SubTrans transitiveSub = validator.createAndValidateTransitiveSubWithoutIdentity(semanticSub);

        Types entities = validator.createEntityTypes(transitiveSub);
        for (Type type : Arrays.asList(type0, type1, type2)) {
            assertTrue(entities.contains(type));
        }
        Types relations = validator.createRelationTypes(transitiveSub);
        for (Type type : Arrays.asList(type3, type4)) {
            assertTrue(relations.contains(type));
        }
        Types attributes = validator.createAttributeTypes(transitiveSub);
        assertEquals(attributes.size(), 0);
    }
}

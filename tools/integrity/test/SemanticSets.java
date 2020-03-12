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

import grakn.client.concept.Label;
import grakn.client.concept.SchemaConcept;
import grakn.common.util.Pair;
import grakn.verification.tools.integrity.schema.Has;
import grakn.verification.tools.integrity.schema.Plays;
import grakn.verification.tools.integrity.schema.Relates;
import grakn.verification.tools.integrity.schema.Sub;
import grakn.verification.tools.integrity.schema.TransitiveSub;
import org.hamcrest.CoreMatchers;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.ExpectedException;

import static org.junit.Assert.assertNotNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Unit test the behaviors of the validation of the various types of semantic sets
 */
public class SemanticSets {
    @Rule
    public final ExpectedException exception = ExpectedException.none();

    @Test
    public void noDuplicateSemanticSetThrowException() {
        RejectDuplicateSet<Integer> rejectDuplicateSet = new RejectDuplicateSet<Integer>() {
            @Override
            public void validate() {
            }
        };

        rejectDuplicateSet.add(1);
        rejectDuplicateSet.add(2);
        exception.expect(IntegrityException.class);
        exception.expectMessage(CoreMatchers.containsString("Duplicate insertion of item: 1"));
        rejectDuplicateSet.add(1);
    }

    @Test
    public void subTransitiveSet_noExceptionWhenConstraintsSatisfied() {
        TransitiveSub transitiveSubSet = new TransitiveSub();

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

        transitiveSubSet.add(sub1);
        transitiveSubSet.add(sub2);
        transitiveSubSet.add(sub3);
        transitiveSubSet.add(sub4);
        transitiveSubSet.add(sub5);
        transitiveSubSet.add(sub6);
        transitiveSubSet.add(sub7);
        transitiveSubSet.add(sub8);

        // transitive subs
        Pair<Type, Type> transSub1 = new Pair<>(type0, type2);
        Pair<Type, Type> transSub2 = new Pair<>(type0, type5);
        Pair<Type, Type> transSub3 = new Pair<>(type0, type8);

        Pair<Type, Type> transSub4 = new Pair<>(type1, type2);
        Pair<Type, Type> transSub5 = new Pair<>(type1, type5);
        Pair<Type, Type> transSub6 = new Pair<>(type1, type8);

        Pair<Type, Type> transSub8 = new Pair<>(type2, type8);

        Pair<Type, Type> transSub10 = new Pair<>(type4, type8);
        Pair<Type, Type> transSub12 = new Pair<>(type3, type8);

        transitiveSubSet.add(transSub1);
        transitiveSubSet.add(transSub2);
        transitiveSubSet.add(transSub3);
        transitiveSubSet.add(transSub4);
        transitiveSubSet.add(transSub5);
        transitiveSubSet.add(transSub6);
        transitiveSubSet.add(transSub8);
        transitiveSubSet.add(transSub10);
        transitiveSubSet.add(transSub12);

        transitiveSubSet.validate();
    }

    @Test
    public void subTransitiveSet_validateMultipleMetaSuperTypes() {
        TransitiveSub transitiveSubSet = new TransitiveSub();

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
//        Pair<Type, Type> sub3 = new Pair<>(type2, type5);
        Pair<Type, Type> sub4 = new Pair<>(type3, type6);
        Pair<Type, Type> sub5 = new Pair<>(type4, type6);
        // meta schema subtyping
        Pair<Type, Type> sub6 = new Pair<>(type5, type8);
        Pair<Type, Type> sub7 = new Pair<>(type6, type8);
        Pair<Type, Type> sub8 = new Pair<>(type7, type8);

        transitiveSubSet.add(sub1);
        transitiveSubSet.add(sub2);
//        subTransSet.add(sub3);
        transitiveSubSet.add(sub4);
        transitiveSubSet.add(sub5);
        transitiveSubSet.add(sub6);
        transitiveSubSet.add(sub7);
        transitiveSubSet.add(sub8);

        // transitive subs
        Pair<Type, Type> transSub1 = new Pair<>(type0, type2);
        Pair<Type, Type> transSub2 = new Pair<>(type0, type5);
        Pair<Type, Type> transSub3 = new Pair<>(type0, type8);

        Pair<Type, Type> transSub4 = new Pair<>(type1, type2);
        Pair<Type, Type> transSub5 = new Pair<>(type1, type5);
        Pair<Type, Type> transSub6 = new Pair<>(type1, type8);

        Pair<Type, Type> transSub8 = new Pair<>(type2, type8);

        Pair<Type, Type> transSub10 = new Pair<>(type4, type8);
        Pair<Type, Type> transSub12 = new Pair<>(type3, type8);

        transitiveSubSet.add(transSub1);
        transitiveSubSet.add(transSub2);
        transitiveSubSet.add(transSub3);
        transitiveSubSet.add(transSub4);
        transitiveSubSet.add(transSub5);
        transitiveSubSet.add(transSub6);
        transitiveSubSet.add(transSub8);
        transitiveSubSet.add(transSub10);
        transitiveSubSet.add(transSub12);

        exception.expect(IntegrityException.class);
        exception.expectMessage("has 0 meta super types");
        transitiveSubSet.validate();
    }

    @Test
    public void subTransitiveSet_throwOnNoThingMeta() {
        TransitiveSub transitiveSubSet = new TransitiveSub();

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

        transitiveSubSet.add(sub1);
        transitiveSubSet.add(sub2);
        transitiveSubSet.add(sub3);
        transitiveSubSet.add(sub4);
        transitiveSubSet.add(sub5);
        transitiveSubSet.add(sub6);
        transitiveSubSet.add(sub7);
        transitiveSubSet.add(sub8);

        // transitive subs
        Pair<Type, Type> transSub1 = new Pair<>(type0, type2);
        Pair<Type, Type> transSub2 = new Pair<>(type0, type5);
        Pair<Type, Type> transSub3 = new Pair<>(type0, type8);

        Pair<Type, Type> transSub4 = new Pair<>(type1, type2);
        Pair<Type, Type> transSub5 = new Pair<>(type1, type5);
        Pair<Type, Type> transSub6 = new Pair<>(type1, type8);

        Pair<Type, Type> transSub8 = new Pair<>(type2, type8);

        Pair<Type, Type> transSub10 = new Pair<>(type4, type8);
//        Pair<Type, Type> transSub12 = new Pair<>(type3, type8);

        transitiveSubSet.add(transSub1);
        transitiveSubSet.add(transSub2);
        transitiveSubSet.add(transSub3);
        transitiveSubSet.add(transSub4);
        transitiveSubSet.add(transSub5);
        transitiveSubSet.add(transSub6);
        transitiveSubSet.add(transSub8);
        transitiveSubSet.add(transSub10);
//        subTransSet.add(transSub12);

        exception.expect(IntegrityException.class);
        exception.expectMessage("has no Thing super");
        transitiveSubSet.validate();
    }


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

        // this should not error
        TransitiveSub transitiveSub = semanticSub.noIdentityTransitiveSub();
        assertNotNull(transitiveSub);
    }

    @Test
    public void transitiveSubThrowsOnLoop() {
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
//        Pair<Type, Type> sub6 = new Pair<>(type5, type8); // rewire this into a loop rather than to 'thing

        Pair<Type, Type> sub7 = new Pair<>(type6, type8);
        Pair<Type, Type> sub8 = new Pair<>(type7, type8);

        // LOOP inducing
        Pair<Type, Type> subLoop = new Pair<>(type5, type0);

        semanticSub.add(sub1);
        semanticSub.add(sub2);
        semanticSub.add(sub3);
        semanticSub.add(sub4);
        semanticSub.add(sub5);
//        semanticSub.add(sub6);
        semanticSub.add(sub7);
        semanticSub.add(sub8);
        semanticSub.add(subLoop);

        // this should not error
        exception.expect(IntegrityException.class);
        exception.expectMessage("is in a loop in the transitive closure of sub, implying a loop in the type hierarchy");
        semanticSub.validate();

    }


    @Test
    public void hasThrowsIfMetaHasAttribute() {
        SchemaConcept mockSchemaConcept1 = mock(SchemaConcept.class);
        when(mockSchemaConcept1.label()).thenReturn(Label.of("a"));
        SchemaConcept mockSchemaConcept2 = mock(SchemaConcept.class);
        when(mockSchemaConcept2.label()).thenReturn(Label.of("entity"));
        SchemaConcept mockSchemaConcept3 = mock(SchemaConcept.class);
        when(mockSchemaConcept3.label()).thenReturn(Label.of("relation"));
        SchemaConcept mockSchemaConcept4 = mock(SchemaConcept.class);
        when(mockSchemaConcept4.label()).thenReturn(Label.of("attribute"));
        SchemaConcept mockSchemaConcept5 = mock(SchemaConcept.class);
        when(mockSchemaConcept5.label()).thenReturn(Label.of("thing"));

        Type type = new Type(mockSchemaConcept1);
        Type entityMeta = new Type(mockSchemaConcept2);
        Type relationMeta = new Type(mockSchemaConcept3);
        Type attributeMeta = new Type(mockSchemaConcept3);
        Type thingMeta = new Type(mockSchemaConcept5);

        Has hasSet = new Has();
        hasSet.add(new Pair<>(entityMeta, type));
        exception.expect(IntegrityException.class);
        exception.expectMessage("entity meta type may not own attributes");
        hasSet.validate();

        hasSet = new Has();
        hasSet.add(new Pair<>(relationMeta, type));
        exception.expect(IntegrityException.class);
        exception.expectMessage("relation meta type may not own attributes");
        hasSet.validate();

        hasSet = new Has();
        hasSet.add(new Pair<>(attributeMeta, type));
        exception.expect(IntegrityException.class);
        exception.expectMessage("attribute meta type may not own attributes");
        hasSet.validate();

        hasSet = new Has();
        hasSet.add(new Pair<>(thingMeta, type));
        exception.expect(IntegrityException.class);
        exception.expectMessage("thing meta type may not own attributes");
        hasSet.validate();
    }

    @Test
    public void playsThrowsIfMetaPlaysRole() {
        SchemaConcept mockSchemaConcept1 = mock(SchemaConcept.class);
        when(mockSchemaConcept1.label()).thenReturn(Label.of("aRole"));
        SchemaConcept mockSchemaConcept2 = mock(SchemaConcept.class);
        when(mockSchemaConcept2.label()).thenReturn(Label.of("entity"));
        SchemaConcept mockSchemaConcept3 = mock(SchemaConcept.class);
        when(mockSchemaConcept3.label()).thenReturn(Label.of("relation"));
        SchemaConcept mockSchemaConcept4 = mock(SchemaConcept.class);
        when(mockSchemaConcept4.label()).thenReturn(Label.of("attribute"));
        SchemaConcept mockSchemaConcept5 = mock(SchemaConcept.class);
        when(mockSchemaConcept5.label()).thenReturn(Label.of("thing"));

        Type aRole = new Type(mockSchemaConcept1);
        Type entityMeta = new Type(mockSchemaConcept2);
        Type relationMeta = new Type(mockSchemaConcept3);
        Type attributeMeta = new Type(mockSchemaConcept3);
        Type thingMeta = new Type(mockSchemaConcept5);

        Plays playsSet = new Plays();
        playsSet.add(new Pair<>(entityMeta, aRole));
        exception.expect(IntegrityException.class);
        exception.expectMessage("entity meta type may not play roles");
        playsSet.validate();

        playsSet = new Plays();
        playsSet.add(new Pair<>(relationMeta, aRole));
        exception.expect(IntegrityException.class);
        exception.expectMessage("relation meta type may not play roles");
        playsSet.validate();

        playsSet = new Plays();
        playsSet.add(new Pair<>(attributeMeta, aRole));
        exception.expect(IntegrityException.class);
        exception.expectMessage("attribute meta type may not play roles");
        playsSet.validate();

        playsSet = new Plays();
        playsSet.add(new Pair<>(thingMeta, aRole));
        exception.expect(IntegrityException.class);
        exception.expectMessage("thing meta type may not play roles");
        playsSet.validate();
    }

    @Test
    public void relatesThrowsIfMetaRelatesRole() {
        SchemaConcept mockSchemaConcept1 = mock(SchemaConcept.class);
        when(mockSchemaConcept1.label()).thenReturn(Label.of("aRole"));
        SchemaConcept mockSchemaConcept2 = mock(SchemaConcept.class);
        when(mockSchemaConcept2.label()).thenReturn(Label.of("entity"));
        SchemaConcept mockSchemaConcept3 = mock(SchemaConcept.class);
        when(mockSchemaConcept3.label()).thenReturn(Label.of("relation"));
        SchemaConcept mockSchemaConcept4 = mock(SchemaConcept.class);
        when(mockSchemaConcept4.label()).thenReturn(Label.of("attribute"));
        SchemaConcept mockSchemaConcept5 = mock(SchemaConcept.class);
        when(mockSchemaConcept5.label()).thenReturn(Label.of("thing"));

        Type aRole = new Type(mockSchemaConcept1);
        Type entityMeta = new Type(mockSchemaConcept2);
        Type relationMeta = new Type(mockSchemaConcept3);
        Type attributeMeta = new Type(mockSchemaConcept3);
        Type thingMeta = new Type(mockSchemaConcept5);

        Relates relatesSet = new Relates();
        relatesSet.add(new Pair<>(entityMeta, aRole));
        exception.expect(IntegrityException.class);
        exception.expectMessage("entity meta type may not relate roles");
        relatesSet.validate();

        relatesSet = new Relates();
        relatesSet.add(new Pair<>(relationMeta, aRole));
        exception.expect(IntegrityException.class);
        exception.expectMessage("relation meta type may not relate roles");
        relatesSet.validate();

        relatesSet = new Relates();
        relatesSet.add(new Pair<>(attributeMeta, aRole));
        exception.expect(IntegrityException.class);
        exception.expectMessage("attribute meta type may not relate roles");
        relatesSet.validate();

        relatesSet = new Relates();
        relatesSet.add(new Pair<>(thingMeta, aRole));
        exception.expect(IntegrityException.class);
        exception.expectMessage("thing meta type may not relate roles");
        relatesSet.validate();
    }
}

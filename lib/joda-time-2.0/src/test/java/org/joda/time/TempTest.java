/*
 *  Copyright 2001-2011 Stephen Colebourne
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */
package org.joda.time;

import org.joda.time.format.DateTimeFormat;
import org.joda.time.format.DateTimeFormatter;

/**
 * This class is a Junit unit test for YearMonthDay.
 *
 * @author Stephen Colebourne
 */
public class TempTest {

    private static final DateTimeZone PARIS = DateTimeZone.forID("Europe/Paris");
    private static final DateTimeZone SAO_PAOLO = DateTimeZone.forID("America/Sao_Paulo");
    private static final DateTimeZone CHICAGO = DateTimeZone.forID("America/Chicago");

    public static void main(String[] args) {
        
        DateTimeFormatter fmt = DateTimeFormat.forPattern("yyyy-MM-dd'T'HH:mm:ssZZ");

            //Setting 2011 Fall DST day.
            DateTime st = new DateTime(2011, 11, 6, 0, 0, CHICAGO);
            DateTime et = new DateTime(2011, 11, 6, 0, 0, CHICAGO);
            //======================================
        for (int i = 0; i <= 24; i++) {
            try {
                if (i > 0) {
                    st = st.minuteOfDay().addToCopy(60);
                }
                et = et.minuteOfDay().addToCopy(60);

                System.out.println("START TIME = { " + fmt.print(st)
                        + " } END TIME =  {" + fmt.print(et) + " }");
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
            //=====================================

//        A a = new A();
//        System.out.println(a.getValue(0));
//        
//        ReadablePartial a1 = a;
//        System.out.println(a1.compareTo(null));
        
        
//        DateTime dt = new DateTime(SAO_PAOLO)
//        .withYear(2011)
//        .withMonthOfYear(10)
//        .withDayOfMonth(15)
//        .withHourOfDay(23)
//        .withMinuteOfHour(59)
//        .withSecondOfMinute(59)
//        .withMillisOfSecond(999);
//        System.out.println(dt);
//        dt = dt.plusMillis(1);
//        System.out.println(dt);
//        
////        DateTime dt2 = new DateTime(SAO_PAOLO)
////        .withYear(2011)
////        .withMonthOfYear(10)
////        .withDayOfMonth(16)
////        .withHourOfDay(0)
////        .withMinuteOfHour(0)
////        .withSecondOfMinute(0)
////        .withMillisOfSecond(0);
//        
//        DateTime dt3 = new DateTime(SAO_PAOLO)
//        .withYear(2011)
//        .withMonthOfYear(10)
//        .withDayOfMonth(16)
//        .withTimeAtStartOfDay();
////        .millisOfDay()
////        .withMinimumValue();
//        System.out.println(dt3);
//        
//        DateTime dt4 = new DateTime(SAO_PAOLO)
//        .withYear(2011)
//        .withMonthOfYear(10)
//        .withDayOfMonth(16)
//        .toDateMidnight().toDateTime();
//        System.out.println(dt4);
    }

}
